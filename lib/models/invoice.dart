class Invoice {
  final int? id;
  final int projectId;
  final double amount;
  final DateTime date;
  final DateTime dueDate;
  final String status;

  Invoice({
    this.id,
    required this.projectId,
    required this.amount,
    required this.date,
    required this.dueDate,
    required this.status,
  });

  factory Invoice.fromMap(Map<String, dynamic> m) => Invoice(
        id: m['id'] as int?,
        projectId: m['projectId'] as int,
        amount: m['amount'] as double,
        date: DateTime.parse(m['date'] as String),
        dueDate: DateTime.parse(m['dueDate'] as String),
        status: m['status'] as String,
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'projectId': projectId,
      'amount': amount,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  bool get isOverdue => status == 'Overdue';
}
