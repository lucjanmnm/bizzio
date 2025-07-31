import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

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
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _issueDateRange;
  DateTimeRange? _dueDateRange;
  String _selectedStatus = 'All';

  List<Invoice> _invoices = [];
  List<Project> _projects = [];
  Map<int, String> _projectTitles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDbAndLoad();
  }

  Future<void> _initDbAndLoad() async {
    await LocalDb.instance.init();
    await _loadProjects();
    await _loadInvoices();
  }

  Future<void> _loadProjects() async {
    final projects = await LocalDb.instance.getAllProjects();
    setState(() {
      _projects = projects;
      _projectTitles = {
        for (var p in projects) p.id!: p.title
      };
    });
  }

  Future<void> _loadInvoices() async {
    final invoices = await LocalDb.instance.getAllInvoices();
    setState(() {
      _invoices = invoices;
      _isLoading = false;
    });
  }

  Future<void> _deleteInvoice(int id) async {
    await LocalDb.instance.deleteInvoice(id);
    await _loadInvoices();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> _pickIssueDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _issueDateRange = picked);
    }
  }

  Future<void> _pickDueDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _issueDateRange = null;
      _dueDateRange = null;
      _selectedStatus = 'All';
    });
  }

  List<Invoice> get _filteredInvoices {
    return _invoices.where((inv) {
      final search = _searchController.text.trim().toLowerCase();
      final title = _projectTitles[inv.projectId] ?? '';
      final matchesSearch = search.isEmpty ||
          inv.id.toString().contains(search) ||
          title.toLowerCase().contains(search);

      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Paid' && inv.amount == 0) ||
          (_selectedStatus == 'Pending' && inv.amount > 0) ||
          (_selectedStatus == 'Overdue' && inv.isOverdue);

      final matchesIssue = _issueDateRange == null ||
          (inv.date.isAfter(_issueDateRange!.start.subtract(const Duration(days: 1))) &&
           inv.date.isBefore(_issueDateRange!.end.add(const Duration(days: 1))));

      final matchesDue = _dueDateRange == null ||
          (inv.dueDate.isAfter(_dueDateRange!.start.subtract(const Duration(days: 1))) &&
           inv.dueDate.isBefore(_dueDateRange!.end.add(const Duration(days: 1))));

      return matchesSearch && matchesStatus && matchesIssue && matchesDue;
    }).toList();
  }

  Future<void> _exportCsv() async {
    final csv = StringBuffer();
    csv.writeln('ID,Project,Amount,Date,DueDate');
    for (var inv in _invoices) {
      final title = _projectTitles[inv.projectId] ?? inv.projectId.toString();
      csv.writeln(
          '${inv.id},$title,${inv.amount},${_formatDate(inv.date)},${_formatDate(inv.dueDate)}');
    }
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/invoices_export.csv';
    final file = File(path);
    await file.writeAsString(csv.toString());
    Share.shareFiles([path], text: 'Exported Invoices');
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
        );
        await LocalDb.instance.upsertInvoice(inv);
      }
      await _loadInvoices();
    }
  }

  Future<void> _navigateToForm([Invoice? invoice]) async {
    final createdOrUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvoiceFormScreen(invoice: invoice),
      ),
    );
    if (createdOrUpdated == true) {
      await _loadInvoices();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search ID or Project',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (_) => _onSearchChanged(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedStatus,
                        items: ['All', 'Paid', 'Pending', 'Overdue']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedStatus = v);
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _pickIssueDateRange,
                        child: Text(_issueDateRange == null
                            ? 'Issue Date'
                            : '${_issueDateRange!.start.toShortDateString()} – ${_issueDateRange!.end.toShortDateString()}'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _pickDueDateRange,
                        child: Text(_dueDateRange == null
                            ? 'Due Date'
                            : '${_dueDateRange!.start.toShortDateString()} – ${_dueDateRange!.end.toShortDateString()}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear_all),
                        onPressed: _clearFilters,
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
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _filteredInvoices.map((inv) {
                          final title =
                              _projectTitles[inv.projectId] ?? '-';
                          return DataRow(cells: [
                            DataCell(Text(inv.id?.toString() ?? '-')),
                            DataCell(Text(title)),
                            DataCell(
                                Text(inv.amount.toStringAsFixed(2))),
                            DataCell(Text(_formatDate(inv.date))),
                            DataCell(Text(_formatDate(inv.dueDate))),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _navigateToForm(inv),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteInvoice(inv.id!),
                                  tooltip: 'Delete',
                                ),
                              ],
                            )),
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

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

extension DateHelpers on DateTime {
  String toShortDateString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
