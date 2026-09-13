class Note {
  String id;
  String title;
  String content;
  String date;
  String courseTitle;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.courseTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'courseTitle': courseTitle,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      courseTitle: map['courseTitle']?.toString() ?? 'Genel',
    );
  }
}
