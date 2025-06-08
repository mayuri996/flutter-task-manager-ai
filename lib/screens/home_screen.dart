import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../db/task_database.dart';
import 'add_edit_task.dart';
import '../services/sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskDatabase.instance.readAllTasks();
    tasks.sort((a, b) => (b.lastModified ?? 0).compareTo(a.lastModified ?? 0));
    setState(() {
      _tasks = tasks;
    });
  }

  void _addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
    );
    if (result == true) _loadTasks();
  }

  void _editTask(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
    );
    if (result == true) _loadTasks();
  }

  void _deleteTask(Task task) async {
    await TaskDatabase.instance.delete(task.id!);
    await TaskDatabase.instance.addDeletedTaskId(task.id!);
    _loadTasks();
  }

  void _toggleTaskCompletion(Task task, bool? value) async {
    final updatedTask = task.copyWith(
      status: value == true ? 'done' : 'todo',
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
    await TaskDatabase.instance.update(updatedTask);
    _loadTasks();
  }

  Future<void> _syncTasks() async {
    setState(() => _isSyncing = true);
    await SyncService().syncTasks();
    await _loadTasks();
    setState(() => _isSyncing = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sync complete!')));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green.shade600;
      case 'in progress':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  Color _sentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
      case 'strongly positive':
        return Colors.green.shade700;
      case 'neutral':
        return Colors.grey.shade600;
      case 'negative':
      case 'strongly negative':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  String _sentimentEmoji(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return '🙂';
      case 'strongly positive':
        return '💚';
      case 'neutral':
        return '😐';
      case 'negative':
        return '😕';
      case 'strongly negative':
        return '💔';
      default:
        return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Frosted Glass Style AppBar Container
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.task_alt,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Your Tasks',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _isSyncing
                              ? Lottie.asset(
                                  'assets/sync.json',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                )
                              : IconButton(
                                  icon: const Icon(Icons.sync),
                                  onPressed: _syncTasks,
                                  color: Colors.white,
                                ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addTask,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: _tasks.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset('assets/empty.json',
                              width: 200, repeat: false),
                          const SizedBox(height: 12),
                          Text(
                            "No tasks yet 😴",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _addTask,
                            icon: const Icon(Icons.add),
                            label: const Text("Add your first task"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              textStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          )
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        color: Colors.white,
                        backgroundColor: Colors.blueAccent,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return Dismissible(
                              key: ValueKey(task.id),
                              background: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerLeft,
                                color: Colors.red.shade400,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              direction: DismissDirection.startToEnd,
                              confirmDismiss: (direction) => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Task?'),
                                  content: Text(
                                      'Are you sure to delete "${task.title}"?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ),
                              onDismissed: (_) => _deleteTask(task),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black38,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 0, horizontal: 0),
                                    leading: Checkbox(
                                      value: task.status == 'done',
                                      activeColor: Colors.green,
                                      onChanged: (val) =>
                                          _toggleTaskCompletion(task, val),
                                    ),
                                    title: Text(
                                      task.title,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          task.description,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Chip(
                                          label: Text(
                                            task.sentiment ?? 'uncertain',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                                color: _sentimentColor(
                                                    task.sentiment ?? '')),
                                          ),
                                          backgroundColor: _sentimentColor(
                                                  task.sentiment ?? '')
                                              .withOpacity(0.15),
                                          avatar: Text(
                                            _sentimentEmoji(
                                                task.sentiment ?? ''),
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 1, horizontal: 6),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue, size: 20),
                                      onPressed: () => _editTask(task),
                                      padding: const EdgeInsets.all(0),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
