class Invoice {
  final int? id;
  final int projectId;
  final double amount;
  final DateTime date;
  final DateTime dueDate;

  Invoice({
    this.id,
    required this.projectId,
    required this.amount,
    required this.date,
    required this.dueDate,
  });

  /// Czy faktura jest przeterminowana?
  bool get isOverdue {
    final now = DateTime.now();
    return amount > 0 && dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      projectId: map['projectId'] as int,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'amount': amount,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
    };
  }
}