class Project {
  final int? id;
  final int clientId;
  final String title;
  final DateTime dueDate;

  Project({this.id, required this.clientId, required this.title, required this.dueDate});

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int?,
      clientId: map['clientId'] as int,
      title: map['title'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'clientId': clientId,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
    };
  }
}
