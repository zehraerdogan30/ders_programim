import 'package:flutter_test/flutter_test.dart';

import 'package:ders_programi_app/models/course.dart';
import 'package:ders_programi_app/models/note.dart';
import 'package:ders_programi_app/models/todo.dart';

void main() {
  test('Course map round-trip preserves course data', () {
    final course = Course(
      id: 'course-1',
      title: 'BIL321 Veri İletişimi',
      instructor: 'Test Instructor',
      room: 'C-202',
      day: 'Çarşamba',
      startTime: '09:00',
      endTime: '11:50',
      duration: '2s 50dk',
      isOnline: false,
      akts: 5,
      gradeItems: [
        GradeItem(name: 'Vize', weight: 40, score: 80),
        GradeItem(name: 'Final', weight: 60, score: 90),
      ],
    );

    final restored = Course.fromMap(course.toMap());

    expect(restored.title, course.title);
    expect(restored.akts, 5);
    expect(restored.gradeItems.length, 2);
    expect(restored.gradeItems.first.score, 80);
  });

  test('Course safely reads numeric values stored as strings', () {
    final restored = Course.fromMap({
      'id': 'course-2',
      'title': 'Test Course',
      'instructor': 'Instructor',
      'room': 'A-101',
      'day': 'Pazartesi',
      'startTime': '09:00',
      'endTime': '10:00',
      'duration': '1s',
      'isOnline': 'false',
      'akts': '6',
      'gradeItems': [
        {'name': 'Vize', 'weight': '40', 'score': '75'},
      ],
    });

    expect(restored.akts, 6);
    expect(restored.isOnline, isFalse);
    expect(restored.gradeItems.single.weight, 40);
    expect(restored.gradeItems.single.score, 75);
  });

  test('Note map round-trip preserves note data', () {
    final note = Note(
      id: 'note-1',
      title: 'Başlık',
      content: 'İçerik',
      date: '2026-09-13',
      courseTitle: 'Genel',
    );

    final restored = Note.fromMap(note.toMap());
    expect(restored.title, note.title);
    expect(restored.content, note.content);
  });

  test('Todo map round-trip preserves completion state', () {
    final todo = Todo(
      id: 'todo-1',
      task: 'Ödevi tamamla',
      courseTitle: 'BIL321 Veri İletişimi',
      dueDate: '2026-09-20',
      isCompleted: true,
    );

    final restored = Todo.fromMap(todo.toMap());
    expect(restored.task, todo.task);
    expect(restored.isCompleted, isTrue);
  });
}
