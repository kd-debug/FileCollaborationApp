import 'dart:convert';

class FileVersion {
  final int versionNumber;
  final DateTime timestamp;

  FileVersion({
    required this.versionNumber,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'versionNumber': versionNumber,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FileVersion.fromMap(Map<String, dynamic> map) {
    return FileVersion(
      versionNumber: map['versionNumber'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class FileComment {
  final String id;
  final String text;
  final DateTime timestamp;

  FileComment({
    required this.id,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FileComment.fromMap(Map<String, dynamic> map) {
    return FileComment(
      id: map['id'],
      text: map['text'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class FileModel {
  final String id;
  final String name;
  final String type;
  final String description;
  final String ownerUsername; // Added field
  final bool isShared;
  final List<FileVersion> versions;
  final List<FileComment> comments;
  final List<String> sharedWith;
  final DateTime updatedAt;

  FileModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.ownerUsername, // Added field
    this.isShared = false,
    required this.versions,
    required this.comments,
    this.sharedWith = const [],
    required this.updatedAt,
  });

  int get currentVersion => versions.isEmpty ? 0 : versions.last.versionNumber;

  FileModel copyWith({
    String? name,
    String? type,
    String? description,
    String? ownerUsername,
    bool? isShared,
    List<FileVersion>? versions,
    List<FileComment>? comments,
    List<String>? sharedWith,
    DateTime? updatedAt,
  }) {
    return FileModel(
      id: this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      isShared: isShared ?? this.isShared,
      versions: versions ?? this.versions,
      comments: comments ?? this.comments,
      sharedWith: sharedWith ?? this.sharedWith,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'ownerUsername': ownerUsername,
      'isShared': isShared,
      'versions': versions.map((x) => x.toMap()).toList(),
      'comments': comments.map((x) => x.toMap()).toList(),
      'sharedWith': sharedWith,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      description: map['description'],
      ownerUsername: map['ownerUsername'] ?? 'unknown',
      isShared: map['isShared'] ?? false,
      versions: List<FileVersion>.from(
          map['versions']?.map((x) => FileVersion.fromMap(Map<String, dynamic>.from(x))) ?? []),
      comments: List<FileComment>.from(
          map['comments']?.map((x) => FileComment.fromMap(Map<String, dynamic>.from(x))) ?? []),
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
