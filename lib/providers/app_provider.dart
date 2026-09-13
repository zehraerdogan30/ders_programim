import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/note.dart';
import '../models/todo.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  List<Course> _courses = [];
  List<Note> _notes = [];
  List<Todo> _todos = [];

  User? get user => _user;
  List<Course> get courses => _courses;
  List<Note> get notes => _notes;
  List<Todo> get todos => _todos;

  AppProvider() {
    _auth.authStateChanges().listen((User? newUser) {
      if (newUser != null && newUser.emailVerified) {
        _user = newUser;
        fetchCourses();
        fetchNotes();
        fetchTodos();
      } else {
        _user = null;
        _courses = [];
        _notes = [];
        _todos = [];
      }
      notifyListeners();
    });
  }

  // --- Auth İşlemleri ---
  Future<String?> signUp(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
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
      _user = null;
      notifyListeners();

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.reload();
      User? updatedUser = _auth.currentUser;

      if (updatedUser != null && !updatedUser.emailVerified) {
        await _auth.signOut();
        _user = null;
        notifyListeners();
        return 'E-posta adresiniz henüz doğrulanmadı! Lütfen gelen kutunuzdaki onay bağlantısına tıklayın.';
      }

      _user = updatedUser;
      fetchCourses();
      fetchNotes();
      fetchTodos();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // BURASI DÜZELTİLDİ: Parametreler isteğe bağlı yapıldı ([String? email, String? password])
  Future<String?> resendVerificationEmail(
      [String? email, String? password]) async {
    try {
      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user?.sendEmailVerification();
        await _auth.signOut();
        _user = null;
        notifyListeners();
        return null;
      } else if (_auth.currentUser != null) {
        await _auth.currentUser!.sendEmailVerification();
        return null;
      }
      return 'Lütfen e-posta ve şifrenizi kontrol edin.';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _courses = [];
    _notes = [];
    _todos = [];
    notifyListeners();
  }

  // --- Courses ---
  void fetchCourses() {
    if (_user == null) return;
    _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('courses')
        .snapshots()
        .listen((snapshot) {
      _courses = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Course.fromMap(data);
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addCourse(Course course) async {
    if (_user == null) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('courses')
        .add(course.toMap());
  }

  Future<void> updateCourse(Course course) async {
    if (_user == null || course.id.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('courses')
        .doc(course.id)
        .update(course.toMap());
  }

  Future<void> removeCourse(String id) async {
    if (_user == null) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('courses')
        .doc(id)
        .delete();
  }

  Future<void> loadMySelectedCourses() async {
    if (_user == null) return;

    final collection =
        _firestore.collection('users').doc(_user!.uid).collection('courses');
    final snapshot = await collection.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // 2. Tam 9 dersi veritabanına ekle
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

    for (var course in myCourses) {
      await addCourse(course);
    }
  }

  // --- Notes ---
  void fetchNotes() {
    if (_user == null) return;
    _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('notes')
        .snapshots()
        .listen((snapshot) {
      _notes = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Note.fromMap(data);
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addNote(Note note) async {
    if (_user == null) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('notes')
        .add(note.toMap());
  }

  Future<void> removeNote(String id) async {
    if (_user == null) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('notes')
        .doc(id)
        .delete();
  }

  // --- Todos ---
  void fetchTodos() {
    if (_user == null) return;
    _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('todos')
        .snapshots()
        .listen((snapshot) {
      _todos = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Todo.fromMap(data);
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addTodo(Todo todo) async {
    if (_user == null) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('todos')
        .add(todo.toMap());
  }

  Future<void> toggleTodo(String id, bool isCompleted) async {
    if (_user == null) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('todos')
        .doc(id)
        .update({'isCompleted': isCompleted});
  }

  Future<void> removeTodo(String id) async {
    if (_user == null) return;
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('todos')
        .doc(id)
        .delete();
  }
}
