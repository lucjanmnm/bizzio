class Invoice {
  final int? id;
  final int projectId;
  final double amount;
  final DateTime date;

  Invoice({this.id, required this.projectId, required this.amount, required this.date});

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      projectId: map['projectId'] as int,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}