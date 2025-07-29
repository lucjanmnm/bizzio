import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/invoice.dart';
import '../../services/local_db.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice;

  const InvoiceFormScreen({Key? key, this.invoice}) : super(key: key);

  @override
  _InvoiceFormScreenState createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _projectIdCtrl;
  late TextEditingController _amountCtrl;
  DateTime? _issueDate;
  DateTime? _dueDate;
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;
    _projectIdCtrl = TextEditingController(text: inv?.projectId.toString() ?? '');
    _amountCtrl = TextEditingController(text: inv?.amount.toStringAsFixed(2) ?? '');
    _issueDate = inv?.date ?? DateTime.now();
    _dueDate = inv?.dueDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _projectIdCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isIssue) async {
    final initial = isIssue ? _issueDate! : _dueDate!;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          _issueDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _issueDate == null || _dueDate == null) return;
    final id = widget.invoice?.id;
    final projectId = int.parse(_projectIdCtrl.text);
    final amount = double.parse(_amountCtrl.text);
    final invoice = Invoice(
      id: id,
      projectId: projectId,
      amount: amount,
      date: _issueDate!,
      dueDate: _dueDate!,
    );
    await LocalDb.instance.upsertInvoice(invoice);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.invoice != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Invoice' : 'New Invoice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _projectIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Project ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Must be integer';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Must be number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Issue Date'),
                subtitle: Text(_dateFmt.format(_issueDate!)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context, true),
                ),
              ),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(_dateFmt.format(_dueDate!)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context, false),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}