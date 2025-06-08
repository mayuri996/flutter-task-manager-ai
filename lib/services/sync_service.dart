import 'dart:async';
import '../models/task.dart';
import '../db/task_database.dart';

class SyncService {
  // Mock "server" storage (in-memory)
  final List<Task> _serverTasks = [];

  // Simulate network delay
  Future<void> _simulateNetworkDelay([int ms = 1000]) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  // Fetch tasks from "server"
  Future<List<Task>> fetchTasksFromServer() async {
    await _simulateNetworkDelay();
    return List<Task>.from(_serverTasks);
  }

  // Upload or update a task on the "server"
  Future<void> uploadTaskToServer(Task task) async {
    await _simulateNetworkDelay(500);
    final index = _serverTasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _serverTasks[index] = task;
    } else {
      _serverTasks.add(task);
    }
  }

  // Delete task from "server"
  Future<void> deleteTaskFromServer(int id) async {
    await _simulateNetworkDelay(300);
    _serverTasks.removeWhere((t) => t.id == id);
  }

  // Core sync logic to sync local DB and "server"
  Future<void> syncTasks() async {
    List<Task> localTasks = await TaskDatabase.instance.readAllTasks();

    // Seed server with local tasks if empty (so it doesn't delete local tasks on first sync)
    if (_serverTasks.isEmpty) {
      _serverTasks.addAll(localTasks);
    }

    List<Task> serverTasks = await fetchTasksFromServer();

    // Get deleted task IDs to delete on server
    List<int> deletedTaskIds = await TaskDatabase.instance.getDeletedTaskIds();

    // Delete from server those deleted locally
    for (int deletedId in deletedTaskIds) {
      await deleteTaskFromServer(deletedId);
      await TaskDatabase.instance.removeDeletedTaskId(deletedId);
    }

    // Create maps for faster lookup
    final Map<int, Task> localTaskMap = {
      for (var task in localTasks) task.id!: task,
    };
    final Map<int, Task> serverTaskMap = {
      for (var task in serverTasks) task.id!: task,
    };

    List<String> conflictsResolved = [];

    // Sync & resolve conflicts
    for (final localTask in localTasks) {
      final serverTask = serverTaskMap[localTask.id!];

      if (serverTask == null) {
        // Task exists locally but not on server, upload it
        await uploadTaskToServer(localTask);
      } else {
        // Both exist, resolve conflict based on lastModified timestamp
        final localModified = localTask.lastModified ?? 0;
        final serverModified = serverTask.lastModified ?? 0;

        if (localModified > serverModified) {
          // Local is newer, update server
          await uploadTaskToServer(localTask);
          conflictsResolved.add(localTask.title);
        } else if (serverModified > localModified) {
          // Server is newer, update local DB
          await TaskDatabase.instance.update(serverTask);
          conflictsResolved.add(serverTask.title);
        }
        // If equal, do nothing
      }
    }

    // Add new tasks from server to local DB
    for (final serverTask in serverTasks) {
      if (!localTaskMap.containsKey(serverTask.id)) {
        await TaskDatabase.instance.create(serverTask);
      }
    }

    // Now, delete locally tasks deleted on server,
    // but only if those tasks are NOT in deletedTaskIds (already handled)
    final localIds = localTasks.map((t) => t.id!).toSet();
    final serverIds = serverTasks.map((t) => t.id!).toSet();

    for (int localId in localIds) {
      if (!serverIds.contains(localId) && !deletedTaskIds.contains(localId)) {
        await TaskDatabase.instance.delete(localId);
      }
    }

    if (conflictsResolved.isNotEmpty) {
      final message = 'Conflicts resolved for: ${conflictsResolved.join(', ')}';
      print(message); // replace with your Snackbar or UI callback if needed
    }
  }
}
