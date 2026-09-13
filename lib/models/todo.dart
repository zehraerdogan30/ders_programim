class Todo {
  final String id;
  final String task;
  final bool isCompleted;
  final String courseTitle; // İlişkili ders adı
  final String dueDate;

  Todo({
    required this.id,
    required this.task,
    this.isCompleted = false,
    this.courseTitle = 'Genel',
    this.dueDate = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'isCompleted': isCompleted,
      'courseTitle': courseTitle,
      'dueDate': dueDate,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] ?? '',
      task: map['task'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      courseTitle: map['courseTitle'] ?? 'Genel',
      dueDate: map['dueDate'] ?? '',
    );
  }
}