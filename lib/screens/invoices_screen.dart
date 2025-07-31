import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/invoice.dart';
import '../models/project.dart';
import '../services/local_db.dart';
import 'forms/invoice_form_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTimeRange? _issueRange, _dueRange;
  String _filterStatus = 'All';

  List<Invoice> _invoices = [];
  List<Project> _projects = [];
  Map<int, String> _titles = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await LocalDb.instance.init();
    _projects = await LocalDb.instance.getAllProjects();
    _titles = { for (var p in _projects) p.id!: p.title };
    _invoices = await LocalDb.instance.getAllInvoices();
    setState(() => _loading = false);
  }

  List<Invoice> get _filtered {
    return _invoices.where((inv) {
      final s = _searchCtrl.text.trim().toLowerCase();
      final title = _titles[inv.projectId]?.toLowerCase() ?? '';
      final f1 = s.isEmpty ||
          inv.id.toString().contains(s) ||
          title.contains(s);
      final f2 = _filterStatus == 'All' || inv.status == _filterStatus;
      final f3 = _issueRange == null ||
          (inv.date.isAfter(_issueRange!.start.subtract(const Duration(days: 1))) &&
           inv.date.isBefore(_issueRange!.end.add(const Duration(days: 1))));
      final f4 = _dueRange == null ||
          (inv.dueDate.isAfter(_dueRange!.start.subtract(const Duration(days: 1))) &&
           inv.dueDate.isBefore(_dueRange!.end.add(const Duration(days: 1))));
      return f1 && f2 && f3 && f4;
    }).toList();
  }

  Future<void> _delete(int id) async {
    await LocalDb.instance.deleteInvoice(id);
    _invoices = await LocalDb.instance.getAllInvoices();
    setState(() {});
  }

  Future<void> _pickIssue() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (r != null) setState(() => _issueRange = r);
  }

  Future<void> _pickDue() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (r != null) setState(() => _dueRange = r);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _exportCsv() async {
    final buf = StringBuffer()..writeln('ID,Project,Amount,Date,DueDate,Status');
    for (var inv in _invoices) {
      final t = _titles[inv.projectId] ?? inv.projectId.toString();
      buf.writeln(
        '${inv.id},$t,${inv.amount},${_fmt(inv.date)},${_fmt(inv.dueDate)},${inv.status}',
      );
    }

    final path = await getSavePath(
      suggestedName: 'invoices_export.csv',
      acceptedTypeGroups: [ const XTypeGroup(label: 'CSV', extensions: ['csv']) ],
    );
    if (path == null) return;

    final file = File(path);
    await file.writeAsString(buf.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zapisano CSV: $path')),
    );
  }

  Future<void> _exportPdfAll() async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final headers = ['ID','Project','Amount','Date','DueDate','Status'];
    final data = _invoices.map((inv) {
      final t = _titles[inv.projectId] ?? '-';
      return [
        inv.id.toString(),
        t,
        inv.amount.toStringAsFixed(2),
        _fmt(inv.date),
        _fmt(inv.dueDate),
        inv.status,
      ];
    }).toList();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (_) => pw.Table.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(font: ttf, fontSize: 10),
        cellStyle: pw.TextStyle(font: ttf, fontSize: 8),
      ),
    ));

    final bytes = await pdf.save();
    final path = await getSavePath(
      suggestedName: 'invoices_export.pdf',
      acceptedTypeGroups: [ const XTypeGroup(label: 'PDF', extensions: ['pdf']) ],
    );
    if (path == null) return;

    final file = File(path);
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zapisano PDF: $path')),
    );
  }

  Future<void> _exportSinglePdf(Invoice inv) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final headers = ['Field','Value'];
    final data = [
      ['ID', inv.id.toString()],
      ['Project', _titles[inv.projectId] ?? '-'],
      ['Amount', inv.amount.toStringAsFixed(2)],
      ['Issue Date', _fmt(inv.date)],
      ['Due Date', _fmt(inv.dueDate)],
      ['Status', inv.status],
    ];

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Table.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(font: ttf, fontSize: 12),
        cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
      ),
    ));

    final bytes = await pdf.save();
    final path = await getSavePath(
      suggestedName: 'invoice_${inv.id}.pdf',
      acceptedTypeGroups: [ const XTypeGroup(label: 'PDF', extensions: ['pdf']) ],
    );
    if (path == null) return;

    final file = File(path);
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zapisano fakturę #${inv.id}: $path')),
    );
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      final content = await File(result.files.single.path!).readAsString();
      final lines = const LineSplitter().convert(content);
      for (var i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',');
        final title = cols[1];
        final matching = _projects.firstWhere(
          (p) => p.title == title,
          orElse: () => Project(
            id: int.tryParse(cols[1]),
            title: title,
            clientId: 0,
            dueDate: DateTime.now(),
          ),
        );
        final inv = Invoice(
          id: int.tryParse(cols[0]),
          projectId: matching.id ?? int.parse(cols[1]),
          amount: double.parse(cols[2]),
          date: DateTime.parse(cols[3]),
          dueDate: DateTime.parse(cols[4]),
          status: cols.length > 5 ? cols[5] : 'Pending',
        );
        await LocalDb.instance.upsertInvoice(inv);
      }
      _invoices = await LocalDb.instance.getAllInvoices();
      setState(() {});
    }
  }

  Future<void> _navigateToForm([Invoice? inv]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceFormScreen(invoice: inv),
      ),
    );
    if (ok == true) {
      _invoices = await LocalDb.instance.getAllInvoices();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdfAll,
            tooltip: 'Export All to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _importCsv,
            tooltip: 'Import CSV',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(),
            tooltip: 'New Invoice',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Search ID/Project',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: ['All', 'Paid', 'Pending', 'Overdue']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _filterStatus = v!),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _pickIssue,
                        child: Text(_issueRange == null
                            ? 'Issue Date'
                            : '${_fmt(_issueRange!.start)} – ${_fmt(_issueRange!.end)}'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _pickDue,
                        child: Text(_dueRange == null
                            ? 'Due Date'
                            : '${_fmt(_dueRange!.start)} – ${_fmt(_dueRange!.end)}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear_all),
                        onPressed: () {
                          _searchCtrl.clear();
                          _issueRange = null;
                          _dueRange = null;
                          _filterStatus = 'All';
                          setState(() {});
                        },
                        tooltip: 'Clear Filters',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Project')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Issue Date')),
                          DataColumn(label: Text('Due Date')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _filtered.map((inv) {
                          final t = _titles[inv.projectId] ?? '-';
                          return DataRow(cells: [
                            DataCell(Text(inv.id?.toString() ?? '-')),
                            DataCell(Text(t)),
                            DataCell(Text(inv.amount.toStringAsFixed(2))),
                            DataCell(Text(_fmt(inv.date))),
                            DataCell(Text(_fmt(inv.dueDate))),
                            DataCell(Text(inv.status)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf),
                                    tooltip: 'Export PDF',
                                    onPressed: () => _exportSinglePdf(inv),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        _navigateToForm(inv),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Delete',
                                    onPressed: () => _delete(inv.id!),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
