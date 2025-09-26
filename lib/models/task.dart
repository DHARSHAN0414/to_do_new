import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final String ownerId;
  final List<String> sharedWith;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.ownerId,
    this.sharedWith = const [],
    this.completed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? ownerId,
    List<String>? sharedWith,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      sharedWith: sharedWith ?? this.sharedWith,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ownerId': ownerId,
      'sharedWith': sharedWith,
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    final Timestamp? createdTs = data['createdAt'] as Timestamp?;
    final Timestamp? updatedTs = data['updatedAt'] as Timestamp?;
    return Task(
      id: id,
      title: (data['title'] ?? '') as String,
      description: data['description'] as String?,
      ownerId: (data['ownerId'] ?? '') as String,
      sharedWith: (data['sharedWith'] as List<dynamic>?)?.cast<String>() ?? const [],
      completed: (data['completed'] as bool?) ?? false,
      createdAt: createdTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory Task.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Task.fromMap(doc.id, doc.data() ?? const {});
  }
}


