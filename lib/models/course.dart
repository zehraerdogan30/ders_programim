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
    final rawWeight = map['weight'];
    final rawScore = map['score'];

    return GradeItem(
      name: map['name']?.toString() ?? '',
      weight: rawWeight is num
          ? rawWeight.toDouble()
          : double.tryParse(rawWeight?.toString() ?? '') ?? 0.0,
      score: rawScore == null
          ? null
          : rawScore is num
              ? rawScore.toDouble()
              : double.tryParse(rawScore.toString()),
    );
  }
}

class Course {
  String id;
  String title;
  String instructor;
  String instructorEmail;
  String room;
  String day;
  String startTime;
  String endTime;
  String duration;
  bool isOnline;
  String classLink;
  String driveLink;
  int akts;
  List<GradeItem> gradeItems;

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
    required this.isOnline,
    this.classLink = '',
    this.driveLink = '',
    this.akts = 4,
    List<GradeItem>? gradeItems,
  }) : gradeItems = gradeItems ??
            [
              GradeItem(name: 'Vize', weight: 40),
              GradeItem(name: 'Final', weight: 60),
            ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'gradeItems': gradeItems.map((x) => x.toMap()).toList(),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    final rawAkts = map['akts'];
    final rawGradeItems = map['gradeItems'];
    final rawOnline = map['isOnline'];

    return Course(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      instructor: map['instructor']?.toString() ?? '',
      instructorEmail: map['instructorEmail']?.toString() ?? '',
      room: map['room']?.toString() ?? '',
      day: map['day']?.toString() ?? 'Pazartesi',
      startTime: map['startTime']?.toString() ?? '09:00',
      endTime: map['endTime']?.toString() ?? '11:50',
      duration: map['duration']?.toString() ?? '2s 50dk',
      isOnline: rawOnline is bool
          ? rawOnline
          : rawOnline?.toString().toLowerCase() == 'true',
      classLink: map['classLink']?.toString() ?? '',
      driveLink: map['driveLink']?.toString() ?? '',
      akts: rawAkts is num
          ? rawAkts.toInt()
          : int.tryParse(rawAkts?.toString() ?? '') ?? 4,
      gradeItems: rawGradeItems is List
          ? rawGradeItems
              .whereType<Map>()
              .map(
                (item) => GradeItem.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : null,
    );
  }
}
