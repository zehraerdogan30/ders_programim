import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/note.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isEn = provider.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFF141923),
      body: provider.notes.isEmpty
          ? Center(
              child: Text(
                isEn ? 'No notes added yet.' : 'Henüz not eklenmedi.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notes.length,
              itemBuilder: (context, index) {
                final note = provider.notes[index];
                final displayCourse = note.courseTitle == 'Genel' && isEn ? 'General' : note.courseTitle;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2638),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              displayCourse,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(note.content, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => provider.removeNote(note.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEn = provider.isEnglish;

    String selectedCourse = isEn ? 'General' : 'Genel';
    final defaultCourseName = isEn ? 'General' : 'Genel';

    List<String> courseTitles = [defaultCourseName, ...provider.courses.map((c) => c.title)];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          title: Text(
            isEn ? 'Add New Note' : 'Yeni Not Ekle',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCourse,
                dropdownColor: const Color(0xFF1E2638),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isEn ? 'Related Course' : 'İlişkili Ders',
                  labelStyle: const TextStyle(color: Colors.grey),
                ),
                items: courseTitles.map((title) {
                  return DropdownMenuItem(
                    value: title,
                    child: Text(title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedCourse = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isEn ? 'Title' : 'Başlık',
                  labelStyle: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isEn ? 'Note Content' : 'Not İçeriği',
                  labelStyle: const TextStyle(color: Colors.grey),
                ),
              ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isEn ? 'Cancel' : 'İptal',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  await provider.addNote(
                    Note(
                      id: '',
                      title: titleController.text.trim(),
                      content: contentController.text.trim(),
                      date: DateTime.now().toString(),
                      courseTitle: selectedCourse == 'General' ? 'Genel' : selectedCourse,
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: Text(
                isEn ? 'Add' : 'Ekle',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      contentController.dispose();
    });
  }
}