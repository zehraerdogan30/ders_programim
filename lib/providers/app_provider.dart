import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course.dart';
import '../models/note.dart';
import '../models/todo.dart';
import '../services/notification_service.dart';

class AppProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  List<Course> _courses = [];
  List<Note> _notes = [];
  List<Todo> _todos = [];

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _courseSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _noteSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _todoSubscription;

  bool _isEnglish = false;
  bool get isEnglish => _isEnglish;

  User? get user => _user;
  List<Course> get courses => List.unmodifiable(_courses);
  List<Note> get notes => List.unmodifiable(_notes);
  List<Todo> get todos => List.unmodifiable(_todos);

  AppProvider() {
    _loadPreferences();
    _authSubscription = _auth.authStateChanges().listen((newUser) {
      if (newUser != null && newUser.emailVerified) {
        _activateUser(newUser);
      } else {
        _clearSessionData();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getBool('isEnglish');
    if (savedLanguage != null && savedLanguage != _isEnglish) {
      _isEnglish = savedLanguage;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();

    unawaited(
      NotificationService.syncCourseNotifications(
        _courses,
        isEnglish: _isEnglish,
      ),
    );

    SharedPreferences.getInstance().then(
      (preferences) => preferences.setBool('isEnglish', _isEnglish),
    );
  }

  Future<String?> updateDisplayName(String displayName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return _isEnglish ? 'No signed-in user found.' : 'Giriş yapan kullanıcı bulunamadı.';
    }

    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      return _isEnglish ? 'Name cannot be empty.' : 'İsim boş bırakılamaz.';
    }

    try {
      await currentUser.updateDisplayName(trimmedName);
      await _firestore.collection('users').doc(currentUser.uid).set({
        'displayName': trimmedName,
        'email': currentUser.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await currentUser.reload();
      _user = _auth.currentUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  void refreshData() {
    fetchCourses();
    fetchNotes();
    fetchTodos();
  }

  void _activateUser(User newUser) {
    final bool isSameUser = _user?.uid == newUser.uid;
    _user = newUser;

    if (!isSameUser ||
        _courseSubscription == null ||
        _noteSubscription == null ||
        _todoSubscription == null) {
      fetchCourses();
      fetchNotes();
      fetchTodos();
    }

    notifyListeners();
  }

  void _clearSessionData() {
    _cancelDataSubscriptions();

    unawaited(
      NotificationService.syncCourseNotifications(
        const <Course>[],
        isEnglish: _isEnglish,
      ),
    );

    _user = null;
    _courses = [];
    _notes = [];
    _todos = [];
    notifyListeners();
  }

  void _cancelDataSubscriptions() {
    _courseSubscription?.cancel();
    _noteSubscription?.cancel();
    _todoSubscription?.cancel();
    _courseSubscription = null;
    _noteSubscription = null;
    _todoSubscription = null;
  }

  Future<String?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await credential.user!.sendEmailVerification();
      }

      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.reload();
      final updatedUser = _auth.currentUser;

      if (updatedUser != null && !updatedUser.emailVerified) {
        await _auth.signOut();
        return _isEnglish
            ? 'Your email address is not verified yet. Please click the verification link in your inbox.'
            : 'E-posta adresiniz henüz doğrulanmadı! Lütfen gelen kutunuzdaki onay bağlantısına tıklayın.';
      }

      if (updatedUser == null) {
        return _isEnglish
            ? 'Unable to read the signed-in user. Please try again.'
            : 'Giriş yapan kullanıcı bilgisi alınamadı. Lütfen tekrar deneyin.';
      }

      _activateUser(updatedUser);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resendVerificationEmail([
    String? email,
    String? password,
  ]) async {
    try {
      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user?.sendEmailVerification();
        await _auth.signOut();
        return null;
      }

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.sendEmailVerification();
        return null;
      }

      return _isEnglish
          ? 'Please check your email and password.'
          : 'Lütfen e-posta ve şifrenizi kontrol edin.';
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    _cancelDataSubscriptions();

    await NotificationService.syncCourseNotifications(
      const <Course>[],
      isEnglish: _isEnglish,
    );

    await _auth.signOut();
    _user = null;
    _courses = [];
    _notes = [];
    _todos = [];
    notifyListeners();
  }

  void fetchCourses() {
    final user = _user;
    if (user == null) return;

    _courseSubscription?.cancel();
    final uid = user.uid;
    _courseSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('courses')
        .snapshots()
        .listen((snapshot) {
      if (_user?.uid != uid) return;
      _courses = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Course.fromMap(data);
      }).toList();

      unawaited(
        NotificationService.syncCourseNotifications(
          _courses,
          isEnglish: _isEnglish,
        ),
      );

      notifyListeners();
    });
  }

  Future<void> addCourse(Course course) async {
    final user = _user;
    if (user == null) return;

    final document = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('courses')
        .add(course.toMap());

    course.id = document.id;

    await NotificationService.scheduleCourseNotification(
      course,
      isEnglish: _isEnglish,
    );
  }

  Future<void> updateCourse(Course course) async {
    final user = _user;
    if (user == null || course.id.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('courses')
        .doc(course.id)
        .update(course.toMap());

    await NotificationService.scheduleCourseNotification(
      course,
      isEnglish: _isEnglish,
    );
  }

  Future<void> removeCourse(String id) async {
    final user = _user;
    if (user == null || id.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('courses')
        .doc(id)
        .delete();

    await NotificationService.cancelCourseNotification(id);
  }

  Future<void> loadMySelectedCourses() async {
    final user = _user;
    if (user == null) return;

    final collection =
        _firestore.collection('users').doc(user.uid).collection('courses');
    final snapshot = await collection.get();

    if (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    final myCourses = [
      Course(
        id: '',
        title: 'EEE328 Digital Signal Processing',
        instructor: 'Fatma Nur Akı',
        room: 'B-214',
        day: 'Pazartesi',
        startTime: '14:00',
        endTime: '16:50',
        duration: '2s 50dk',
        isOnline: false,
      ),
      Course(
        id: '',
        title: 'ENG305 Prep. & Mgmt. of Research Projects',
        instructor: 'İlker Köse',
        room: 'Uzaktan Eğitim',
        day: 'Salı',
        startTime: '19:00',
        endTime: '20:50',
        duration: '1s 50dk',
        isOnline: true,
      ),
      Course(
        id: '',
        title: 'BIL321 Veri İletişimi',
        instructor: 'Ağah Tuğrul Korucu',
        room: 'C-202',
        day: 'Çarşamba',
        startTime: '09:00',
        endTime: '11:50',
        duration: '2s 50dk',
        isOnline: false,
      ),
      Course(
        id: '',
        title: 'BIL317 Discrete Mathematics',
        instructor: 'Fatih Mert',
        room: 'B-111',
        day: 'Perşembe',
        startTime: '09:00',
        endTime: '11:50',
        duration: '2s 50dk',
        isOnline: false,
      ),
      Course(
        id: '',
        title: 'GNL367 Dünya Siyasetinde Güncel Sorunlar',
        instructor: 'Hacı Uğur Polat',
        room: 'B-212',
        day: 'Perşembe',
        startTime: '15:00',
        endTime: '17:50',
        duration: '2s 50dk',
        isOnline: false,
      ),
      Course(
        id: '',
        title: 'BIL453 Bilgisayar Sistemleri Lab.',
        instructor: 'Ufuk Şanver',
        room: 'C-205',
        day: 'Perşembe',
        startTime: '18:00',
        endTime: '19:50',
        duration: '1s 50dk',
        isOnline: false,
      ),
      Course(
        id: '',
        title: 'BIL451 Bilişim Tasarım Projesi',
        instructor: 'Sevcan Kahraman',
        room: '',
        day: 'Cumartesi',
        startTime: '09:00',
        endTime: '12:50',
        duration: '3s 50dk',
        isOnline: false,
      ),
      Course(
        id: '',
        title: 'BIL353 Artificial Intelligence',
        instructor: 'Metin Turan',
        room: 'C-303 / B-117',
        day: 'Cuma',
        startTime: '10:00',
        endTime: '12:50',
        duration: '2s 50dk',
        isOnline: false,
      ),
      Course(
        id: '',
        title: 'BIL331 Microprocessor Systems',
        instructor: 'Muhammed Talha Büyükakkaşlar',
        room: 'C-303',
        day: 'Cuma',
        startTime: '14:00',
        endTime: '16:50',
        duration: '2s 50dk',
        isOnline: false,
      ),
    ];

    for (final course in myCourses) {
      await addCourse(course);
    }
  }

  void fetchNotes() {
    final user = _user;
    if (user == null) return;

    _noteSubscription?.cancel();
    final uid = user.uid;
    _noteSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('notes')
        .snapshots()
        .listen((snapshot) {
      if (_user?.uid != uid) return;
      _notes = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Note.fromMap(data);
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addNote(Note note) async {
    final user = _user;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .add(note.toMap());
  }

  Future<void> removeNote(String id) async {
    final user = _user;
    if (user == null || id.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(id)
        .delete();
  }

  void fetchTodos() {
    final user = _user;
    if (user == null) return;

    _todoSubscription?.cancel();
    final uid = user.uid;
    _todoSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('todos')
        .snapshots()
        .listen((snapshot) {
      if (_user?.uid != uid) return;
      _todos = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Todo.fromMap(data);
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addTodo(Todo todo) async {
    final user = _user;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .add(todo.toMap());
  }

  Future<void> toggleTodo(String id, bool isCompleted) async {
    final user = _user;
    if (user == null || id.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .doc(id)
        .update({'isCompleted': isCompleted});
  }

  Future<void> removeTodo(String id) async {
    final user = _user;
    if (user == null || id.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .doc(id)
        .delete();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelDataSubscriptions();
    super.dispose();
  }
}
