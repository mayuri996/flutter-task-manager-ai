import 'package:flutter/material.dart';
import '../models/task.dart';
import '../db/task_database.dart';
import '../services/sentiment_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  String _status = 'todo';

  @override
  void initState() {
    super.initState();
    _title = widget.task?.title ?? '';
    _description = widget.task?.description ?? '';
    _status = widget.task?.status ?? 'todo';
    SentimentService().init();
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final inputText = '$_title $_description';
      String sentiment;

      try {
        sentiment = await SentimentService().classify(inputText);
        if (sentiment.trim().isEmpty || sentiment == 'error') {
          sentiment = 'uncertain';
        }
      } catch (e) {
        sentiment = 'uncertain';
      }

      if (widget.task == null) {
        await TaskDatabase.instance.create(
          Task(
            title: _title,
            description: _description,
            status: _status,
            sentiment: sentiment,
          ),
        );
      } else {
        final updatedTask = widget.task!.copyWith(
          title: _title,
          description: _description,
          status: _status,
          sentiment: sentiment,
        );
        await TaskDatabase.instance.update(updatedTask);
      }

      Navigator.pop(context, true);
    }
  }

  InputDecoration _styledInput(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          icon != null ? Icon(icon, color: Colors.green.shade700) : null,
      labelStyle: const TextStyle(fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  // New gradient for AppBar & Button background
  final LinearGradient _greenGradient = const LinearGradient(
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF81C784)
    ], // dark green to lighter green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        elevation: 6,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _greenGradient,
          ),
        ),
        shadowColor: Colors.green.shade200,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _title,
                      decoration: _styledInput('Title', icon: Icons.title),
                      validator: (value) => value!.trim().isEmpty
                          ? 'Please enter a title ✍️'
                          : null,
                      onSaved: (value) => _title = value!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description,
                      maxLines: 3,
                      decoration:
                          _styledInput('Description', icon: Icons.description),
                      onSaved: (value) => _description = value?.trim() ?? '',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: _styledInput('Status', icon: Icons.flag),
                      borderRadius: BorderRadius.circular(14),
                      items: const [
                        DropdownMenuItem(
                          value: 'todo',
                          child: Text('📝 To Do'),
                        ),
                        DropdownMenuItem(
                          value: 'in progress',
                          child: Text('🚧 In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'done',
                          child: Text('✅ Done'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _status = value!);
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTask,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.transparent,
                        ).copyWith(
                          // override background color with gradient using Ink
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color?>(
                            (states) => null,
                          ),
                          shadowColor:
                              MaterialStateProperty.all(Colors.transparent),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _greenGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Text(
                              isEditing ? 'Update Task' : 'Add Task',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
