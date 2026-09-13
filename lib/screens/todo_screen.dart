import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/todo.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF141923),
      appBar: AppBar(
        title: const Text('Yapılacaklar & Ödevler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2638),
        elevation: 0,
      ),
      body: provider.todos.isEmpty
          ? const Center(child: Text('Henüz görev eklenmedi.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.todos.length,
              itemBuilder: (context, index) {
                final todo = provider.todos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2638),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    subtitle: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            todo.courseTitle,
                            style: const TextStyle(color: Colors.tealAccent, fontSize: 10),
                          ),
                        ),
                        if (todo.dueDate.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Teslim: ${todo.dueDate}',
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                          ),
                        ],
                      ],
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

  void _showAddTodoDialog(BuildContext context) {
    final taskController = TextEditingController();
    final dueDateController = TextEditingController();
    final provider = Provider.of<AppProvider>(context, listen: false);
    String selectedCourse = 'Genel';

    List<String> courseTitles = ['Genel', ...provider.courses.map((c) => c.title)];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          title: const Text('Yeni Görev / Ödev', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCourse,
                dropdownColor: const Color(0xFF1E2638),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'İlişkili Ders', labelStyle: TextStyle(color: Colors.grey)),
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
                decoration: const InputDecoration(labelText: 'Görev / Ödev Açıklaması', labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dueDateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Son Teslim Tarihi (Örn: 25 Ekim)', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  provider.addTodo(
                    Todo(
                      id: '',
                      task: taskController.text,
                      courseTitle: selectedCourse,
                      dueDate: dueDateController.text,
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}