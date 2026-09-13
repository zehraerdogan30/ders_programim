class Note {
  final String id;
  final String title;
  final String content;
  final String date;
  final String courseTitle;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.courseTitle = 'Genel'
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'courseTitle': courseTitle,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] ?? '',
      courseTitle: map['courseTitle'] ?? 'Genel',
    );
  }
}