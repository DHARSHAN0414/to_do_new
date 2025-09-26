import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  TaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _collection = (firestore ?? FirebaseFirestore.instance).collection('tasks').withConverter<Task>(
              fromFirestore: (doc, _) => Task.fromDoc(doc),
              toFirestore: (task, _) => task.toMap(),
            );

  final FirebaseFirestore _firestore;
  final CollectionReference<Task> _collection;

  CollectionReference<Task> get collection => _collection;

  Future<Task> createTask({
    required String title,
    String? description,
    required String ownerId,
    List<String> sharedWith = const [],
  }) async {
    final now = DateTime.now();
    final docRef = _collection.doc();
    final task = Task(
      id: docRef.id,
      title: title,
      description: description,
      ownerId: ownerId,
      sharedWith: sharedWith,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(task);
    return task;
  }

  Future<Task?> getTask(String id) async {
    final doc = await _collection.doc(id).get();
    return doc.data();
  }

  Future<void> updateTask(Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    await _collection.doc(task.id).set(updated, SetOptions(merge: true));
  }

  Future<void> deleteTask(String id) async {
    await _collection.doc(id).delete();
  }

  /// Share task with users by email addresses
  Future<void> shareTaskWithEmails(String taskId, List<String> emailAddresses) async {
    if (emailAddresses.isEmpty) return;
    
    // For now, we'll store email addresses directly in sharedWith
    // In a real app, you'd want to resolve emails to user IDs
    final taskDoc = _collection.doc(taskId);
    final task = await getTask(taskId);
    
    if (task != null) {
      final updatedSharedWith = {...task.sharedWith, ...emailAddresses}.toList();
      await taskDoc.update({
        'sharedWith': updatedSharedWith,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  /// Get users by email addresses (placeholder - in real app, query users collection)
  Future<List<String>> getUsersByEmails(List<String> emails) async {
    // This is a placeholder implementation
    // In a real app, you'd query a users collection to resolve emails to user IDs
    return emails;
  }

  /// Create a shareable link for a task
  String generateTaskShareLink(String taskId) {
    // Use Firebase Hosting URL that can be clicked and will redirect to the app
    // This creates a clickable link that opens the app
    return 'https://task-schedule-33122.web.app/task_redirect.html#/task/$taskId';
  }

  /// Create a custom URL scheme for direct app opening
  String generateAppDeepLink(String taskId) {
    // Custom URL scheme for direct app opening
    return 'collabtodo://task/$taskId';
  }

  /// Create a comprehensive share link with both options
  String generateShareLinkWithFallback(String taskId) {
    // Return universal link as primary, with app deep link as fallback
    return generateTaskShareLink(taskId);
  }

  /// Stream a single task for real-time updates
  Stream<Task?> streamTask(String taskId) {
    return _collection.doc(taskId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  /// Check if a task exists and is accessible
  Future<bool> isTaskAccessible(String taskId) async {
    try {
      final doc = await _collection.doc(taskId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Stream<List<Task>> streamTasksForUser(String userId) {
    final asOwnerQuery = _collection.where('ownerId', isEqualTo: userId);
    final asSharedQuery = _collection.where('sharedWith', arrayContains: userId);

    final ownerStream = asOwnerQuery.snapshots();
    final sharedStream = asSharedQuery.snapshots();

    return ownerStream.combineWith(sharedStream).map((tuple) {
      final ownerDocs = tuple.$1.docs.map((d) => d.data());
      final sharedDocs = tuple.$2.docs.map((d) => d.data());
      final map = <String, Task>{};
      for (final t in ownerDocs) {
        map[t.id] = t;
      }
      for (final t in sharedDocs) {
        map[t.id] = t;
      }
      final tasks = map.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return tasks;
    });
  }
}

extension _StreamCombineExt<T> on Stream<QuerySnapshot<T>> {
  Stream<(QuerySnapshot<T>, QuerySnapshot<T>)> combineWith(
    Stream<QuerySnapshot<T>> other,
  ) async* {
    QuerySnapshot<T>? latestA;
    QuerySnapshot<T>? latestB;

    final controller = StreamController<(QuerySnapshot<T>, QuerySnapshot<T>)>();

    late final StreamSubscription subA;
    late final StreamSubscription subB;

    void emitIfReady() {
      if (latestA != null && latestB != null) {
        controller.add((latestA!, latestB!));
      }
    }

    subA = listen((a) {
      latestA = a;
      emitIfReady();
    });

    subB = other.listen((b) {
      latestB = b;
      emitIfReady();
    });

    controller.onCancel = () async {
      await subA.cancel();
      await subB.cancel();
    };

    yield* controller.stream;
  }
}


