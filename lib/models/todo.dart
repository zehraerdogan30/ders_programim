class Todo {
  String id;
  String task;
  String courseTitle;
  String dueDate;
  bool isCompleted;

  Todo({
    required this.id,
    required this.task,
    required this.courseTitle,
    required this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'courseTitle': courseTitle,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    final rawCompleted = map['isCompleted'];

    return Todo(
      id: map['id']?.toString() ?? '',
      task: map['task']?.toString() ?? '',
      courseTitle: map['courseTitle']?.toString() ?? 'Genel',
      dueDate: map['dueDate']?.toString() ?? '',
      isCompleted: rawCompleted is bool
          ? rawCompleted
          : rawCompleted?.toString().toLowerCase() == 'true',
    );
  }
}
