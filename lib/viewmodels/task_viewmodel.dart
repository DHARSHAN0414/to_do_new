import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskViewModel extends ChangeNotifier {
  TaskViewModel({TaskService? taskService}) 
      : _taskService = taskService ?? TaskService();

  final TaskService _taskService;
  String? _currentUserId;
  Stream<List<Task>>? _tasksStream;

  String? get currentUserId => _currentUserId;
  Stream<List<Task>>? get tasksStream => _tasksStream;

  /// Initialize the view model with a user ID
  void initialize(String userId) {
    _currentUserId = userId;
    _tasksStream = _taskService.streamTasksForUser(userId);
    notifyListeners();
  }

  /// Add a new task
  Future<Task?> addTask({
    required String title,
    String? description,
    List<String> sharedWith = const [],
  }) async {
    if (_currentUserId == null) {
      throw Exception('TaskViewModel not initialized. Call initialize() first.');
    }

    try {
      final task = await _taskService.createTask(
        title: title,
        description: description,
        ownerId: _currentUserId!,
        sharedWith: sharedWith,
      );
      return task;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding task: $e');
      }
      rethrow;
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    try {
      await _taskService.updateTask(task);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating task: $e');
      }
      rethrow;
    }
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(completed: !task.completed);
    await updateTask(updatedTask);
  }

  /// Update task title
  Future<void> updateTaskTitle(Task task, String newTitle) async {
    final updatedTask = task.copyWith(title: newTitle);
    await updateTask(updatedTask);
  }

  /// Update task description
  Future<void> updateTaskDescription(Task task, String? newDescription) async {
    final updatedTask = task.copyWith(description: newDescription);
    await updateTask(updatedTask);
  }

  /// Share task with additional users
  Future<void> shareTaskWith(Task task, List<String> userIds) async {
    final updatedSharedWith = {...task.sharedWith, ...userIds}.toList();
    final updatedTask = task.copyWith(sharedWith: updatedSharedWith);
    await updateTask(updatedTask);
  }

  /// Remove users from task sharing
  Future<void> unshareTaskWith(Task task, List<String> userIds) async {
    final updatedSharedWith = task.sharedWith.where((id) => !userIds.contains(id)).toList();
    final updatedTask = task.copyWith(sharedWith: updatedSharedWith);
    await updateTask(updatedTask);
  }

  /// Share task with users by email addresses
  Future<void> shareTaskWithEmails(Task task, List<String> emailAddresses) async {
    try {
      await _taskService.shareTaskWithEmails(task.id, emailAddresses);
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing task with emails: $e');
      }
      rethrow;
    }
  }

  /// Generate a shareable link for a task
  String generateTaskShareLink(Task task) {
    return _taskService.generateTaskShareLink(task.id);
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting task: $e');
      }
      rethrow;
    }
  }

  /// Get a specific task by ID
  Future<Task?> getTask(String taskId) async {
    try {
      return await _taskService.getTask(taskId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting task: $e');
      }
      return null;
    }
  }

  /// Check if the current user can edit a task
  bool canEditTask(Task task) {
    return _currentUserId != null && 
           (task.ownerId == _currentUserId || task.sharedWith.contains(_currentUserId));
  }

  /// Check if the current user owns a task
  bool ownsTask(Task task) {
    return _currentUserId != null && task.ownerId == _currentUserId;
  }

}
