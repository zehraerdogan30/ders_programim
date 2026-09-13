class GradeItem {
  String name;
  double weight;
  double? score;

  GradeItem({
    required this.name,
    required this.weight,
    this.score,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weight': weight,
      'score': score,
    };
  }

  factory GradeItem.fromMap(Map<String, dynamic> map) {
    return GradeItem(
      name: map['name'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      score: (map['score'] as num?)?.toDouble(),
    );
  }
}

class Course {
  final String id;
  final String title;
  final String instructor;
  final String instructorEmail;
  final String room;
  final String day;
  final String startTime;
  final String endTime;
  final String duration;
  final bool isOnline;
  final String classLink;
  final String driveLink;
  final int akts;
  final List<GradeItem> gradeItems;

  Course({
    required this.id,
    required this.title,
    required this.instructor,
    this.instructorEmail = '',
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.isOnline = false,
    this.classLink = '',
    this.driveLink = '',
    this.akts = 4,
    List<GradeItem>? gradeItems,
  }) : gradeItems = gradeItems ?? [
          GradeItem(name: 'Vize', weight: 40),
          GradeItem(name: 'Final', weight: 60),
        ];

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'instructor': instructor,
      'instructorEmail': instructorEmail,
      'room': room,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'isOnline': isOnline,
      'classLink': classLink,
      'driveLink': driveLink,
      'akts': akts,
      'gradeItems': gradeItems.map((item) => item.toMap()).toList(),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    var rawItems = map['gradeItems'] as List?;
    List<GradeItem> parsedItems = rawItems != null
        ? rawItems.map((i) => GradeItem.fromMap(Map<String, dynamic>.from(i))).toList()
        : [
            GradeItem(name: 'Vize', weight: 40),
            GradeItem(name: 'Final', weight: 60),
          ];

    return Course(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      instructor: map['instructor'] ?? '',
      instructorEmail: map['instructorEmail'] ?? '',
      room: map['room'] ?? '',
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      duration: map['duration'] ?? '',
      isOnline: map['isOnline'] ?? false,
      classLink: map['classLink'] ?? '',
      driveLink: map['driveLink'] ?? '',
      akts: map['akts'] ?? 4,
      gradeItems: parsedItems,
    );
  }
}