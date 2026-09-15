import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/todo.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isEn = provider.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFF141923),
      body: provider.todos.isEmpty
          ? Center(
              child: Text(
                isEn ? 'No tasks added yet.' : 'Henüz görev eklenmedi.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.todos.length,
              itemBuilder: (context, index) {
                final todo = provider.todos[index];
                final displayCourse = noteCourseTitle(todo.courseTitle, isEn);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2638),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: CheckboxListTile(
                    activeColor: const Color(0xFF6C5CE7),
                    title: Text(
                      todo.task,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              displayCourse,
                              style: const TextStyle(color: Colors.tealAccent, fontSize: 10),
                            ),
                          ),
                          if (todo.dueDate.isNotEmpty)
                            Text(
                              '${isEn ? 'Due' : 'Teslim'}: ${todo.dueDate}',
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    value: todo.isCompleted,
                    onChanged: (val) => provider.toggleTodo(todo.id, val ?? false),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => provider.removeTodo(todo.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String noteCourseTitle(String courseTitle, bool isEn) {
    if (courseTitle == 'Genel' && isEn) return 'General';
    return courseTitle;
  }

  void _showAddTodoDialog(BuildContext context) {
    final taskController = TextEditingController();
    final dueDateController = TextEditingController();
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
            isEn ? 'New Task / Assignment' : 'Yeni Görev / Ödev',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 8),
              TextField(
                controller: taskController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isEn ? 'Task Description' : 'Görev / Ödev Açıklaması',
                  labelStyle: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dueDateController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isEn ? 'Due Date (e.g. Oct 25)' : 'Son Teslim Tarihi (Örn: 25 Ekim)',
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
                if (taskController.text.trim().isNotEmpty) {
                  await provider.addTodo(
                    Todo(
                      id: '',
                      task: taskController.text.trim(),
                      courseTitle: selectedCourse == 'General' ? 'Genel' : selectedCourse,
                      dueDate: dueDateController.text.trim(),
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
      taskController.dispose();
      dueDateController.dispose();
    });
  }
}