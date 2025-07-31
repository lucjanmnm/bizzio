import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/invoice.dart';
import '../../models/project.dart';
import '../../services/local_db.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice;
  const InvoiceFormScreen({Key? key, this.invoice}) : super(key: key);

  @override
  _InvoiceFormScreenState createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Project> _projects = [];
  int? _projId;
  late TextEditingController _amountCtrl;
  DateTime _issue = DateTime.now();
  DateTime _due = DateTime.now().add(const Duration(days: 30));
  String? _status;
  final _fmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadProjects();
    final inv = widget.invoice;
    if (inv != null) {
      _projId = inv.projectId;
      _amountCtrl = TextEditingController(text: inv.amount.toStringAsFixed(2));
      _issue = inv.date;
      _due = inv.dueDate;
      _status = inv.status;
    } else {
      _amountCtrl = TextEditingController();
      _status = 'Pending';
    }
  }

  Future<void> _loadProjects() async {
    _projects = await LocalDb.instance.getAllProjects();
    setState(() {});
  }

  Future<void> _pickDate(bool isIssue) async {
    final initial = isIssue ? _issue : _due;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) _issue = picked;
        else _due = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final inv = Invoice(
      id: widget.invoice?.id,
      projectId: _projId!,
      amount: double.parse(_amountCtrl.text),
      date: _issue,
      dueDate: _due,
      status: _status!,
    );
    await LocalDb.instance.upsertInvoice(inv);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.invoice != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Invoice' : 'New Invoice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: _projId,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                ),
                items: _projects.map((p)=>DropdownMenuItem(
                  value: p.id, child: Text(p.title)
                )).toList(),
                onChanged: (v)=> setState(()=> _projId = v),
                validator: (v)=> v==null? 'Select project': null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount', border: OutlineInputBorder()),
                keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                validator: (v){
                  if (v==null||v.isEmpty) return 'Required';
                  if (double.tryParse(v)==null) return 'Must be number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Issue Date'),
                subtitle: Text(_fmt.format(_issue)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: ()=> _pickDate(true),
                ),
              ),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(_fmt.format(_due)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: ()=> _pickDate(false),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['Pending','Paid','Overdue']
                  .map((s)=> DropdownMenuItem(
                    value: s, child: Text(s)))
                  .toList(),
                onChanged: (v)=> setState(()=> _status = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
