import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';

class FileProvider with ChangeNotifier {
  static const String _boxName = 'filesBox';
  List<FileModel> _files = [];
  String _searchQuery = '';
  String _selectedType = 'All';
  bool _showOnlyShared = false;
  String? _currentUsername;

  void setCurrentUser(String? username) {
    _currentUsername = username;
    notifyListeners();
  }

  List<FileModel> get files {
    if (_currentUsername == null) return [];

    // Filter: User owns the file OR file is shared with the user
    List<FileModel> filtered = _files.where((f) {
      return f.ownerUsername == _currentUsername || f.sharedWith.contains(_currentUsername!);
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedType != 'All') {
      filtered = filtered.where((f) => f.type == _selectedType).toList();
    }

    if (_showOnlyShared) {
      filtered = filtered.where((f) => f.isShared).toList();
    }

    return filtered;
  }

  List<FileModel> get sharedFiles {
     if (_currentUsername == null) return [];
     return _files.where((f) => f.sharedWith.contains(_currentUsername!)).toList();
  }

  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  bool get showOnlyShared => _showOnlyShared;

  Future<void> init() async {
    try {
      await Hive.openBox(_boxName);
      _loadFiles();
    } catch (e) {
      debugPrint('Hive init error: $e');
    }
  }

  void _loadFiles() {
    try {
      final box = Hive.box(_boxName);
      _files = box.values
          .map((e) {
            try {
              return FileModel.fromMap(Map<String, dynamic>.from(e));
            } catch (e) {
              return null;
            }
          })
          .whereType<FileModel>()
          .toList();
      _files.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      _files = [];
    }
    notifyListeners();
  }

  Future<void> addFile(String name, String type, String description) async {
    if (_currentUsername == null) return;
    
    final id = const Uuid().v4();
    final now = DateTime.now();
    final newFile = FileModel(
      id: id,
      name: name,
      type: type,
      description: description,
      ownerUsername: _currentUsername!,
      versions: [FileVersion(versionNumber: 1, timestamp: now)],
      comments: [],
      sharedWith: [],
      updatedAt: now,
    );

    final box = Hive.box(_boxName);
    await box.put(id, newFile.toMap());
    _loadFiles();
  }

  Future<void> updateFile(String id, {String? name, String? description}) async {
    final index = _files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final oldFile = _files[index];
      final now = DateTime.now();
      
      final nextVersion = oldFile.currentVersion + 1;
      final updatedFile = oldFile.copyWith(
        name: name,
        description: description,
        versions: [...oldFile.versions, FileVersion(versionNumber: nextVersion, timestamp: now)],
        updatedAt: now,
      );

      final box = Hive.box(_boxName);
      await box.put(id, updatedFile.toMap());
      _loadFiles();
    }
  }

  Future<void> toggleShare(String id) async {
    final index = _files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final updatedFile = _files[index].copyWith(
        isShared: !_files[index].isShared,
        sharedWith: !_files[index].isShared ? [] : _files[index].sharedWith,
      );
      final box = Hive.box(_boxName);
      await box.put(id, updatedFile.toMap());
      _loadFiles();
    }
  }

  Future<void> shareWithUser(String fileId, String userName) async {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index != -1) {
      final oldFile = _files[index];
      if (!oldFile.sharedWith.contains(userName)) {
        final updatedFile = oldFile.copyWith(
          isShared: true,
          sharedWith: [...oldFile.sharedWith, userName],
        );
        final box = Hive.box(_boxName);
        await box.put(fileId, updatedFile.toMap());
        _loadFiles();
      }
    }
  }

  Future<void> addComment(String fileId, String text) async {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index != -1) {
      final oldFile = _files[index];
      final newComment = FileComment(
        id: const Uuid().v4(),
        text: text,
        timestamp: DateTime.now(),
      );
      final updatedFile = oldFile.copyWith(
        comments: [...oldFile.comments, newComment],
        updatedAt: DateTime.now(),
      );

      final box = Hive.box(_boxName);
      await box.put(fileId, updatedFile.toMap());
      _loadFiles();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void toggleOnlyShared(bool value) {
    _showOnlyShared = value;
    notifyListeners();
  }

  Future<void> syncData() async {
    await Future.delayed(const Duration(seconds: 2));
    _loadFiles();
  }
}
