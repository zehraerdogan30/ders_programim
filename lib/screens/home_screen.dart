import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'schedule_screen.dart';
import 'todo_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ScheduleScreen(),
    const TodoScreen(),
    const NotesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isEn = provider.isEnglish;

    String getTitle() {
      switch (_currentIndex) {
        case 0:
          return isEn ? 'Weekly Schedule' : 'Haftalık Program';
        case 1:
          return isEn ? 'To-Dos & Tasks' : 'Yapılacaklar & Ödevler';
        case 2:
          return isEn ? 'My Notes' : 'Notlarım';
        case 3:
          return isEn ? 'Profile & Settings' : 'Profil & Ayarlar';
        default:
          return '';
      }
    }

    String getSubtitle() {
      switch (_currentIndex) {
        case 0:
          return isEn
              ? '${provider.courses.length} courses registered'
              : '${provider.courses.length} ders kayıtlı';
        case 1:
          return isEn
              ? '${provider.todos.length} tasks total'
              : '${provider.todos.length} görev mevcut';
        case 2:
          return isEn
              ? '${provider.notes.length} notes saved'
              : '${provider.notes.length} not kayıtlı';
        case 3:
          return provider.user?.email ?? '';
        default:
          return '';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF131824),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131824),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTitle(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (getSubtitle().isNotEmpty)
              Text(
                getSubtitle(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.language, color: Color(0xFF6C5CE7)),
            label: Text(
              isEn ? 'EN' : 'TR',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () => provider.toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => provider.loadMySelectedCourses(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => provider.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E2638),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_rounded),
            label: isEn ? 'Schedule' : 'Program',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.check_box_rounded),
            label: isEn ? 'To-Dos' : 'Yapılacaklar',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_note_rounded),
            label: isEn ? 'Notes' : 'Notlar',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: isEn ? 'Profile' : 'Profil',
          ),
        ],
      ),
    );
  }
}