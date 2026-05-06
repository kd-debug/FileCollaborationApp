import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../services/database_service.dart';

class FileProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
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

    List<FileModel> filtered = _files.where((f) {
      return f.ownerUsername == _currentUsername || f.sharedWith.contains(_currentUsername!);
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
    _loadFiles();
  }

  void _loadFiles() {
    _files = _dbService.getAllFiles();
    _files.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<void> addFile(String name, String type, String description) async {
    if (_currentUsername == null) return;
    
    final file = FileModel(
      id: const Uuid().v4(),
      name: name,
      type: type,
      description: description,
      ownerUsername: _currentUsername!,
      versions: [FileVersion(versionNumber: 1, timestamp: DateTime.now())],
      comments: [],
      sharedWith: [],
      updatedAt: DateTime.now(),
    );

    await _dbService.saveFile(file);
    _loadFiles();
  }

  Future<void> updateFile(String id, {String? name, String? description}) async {
    final index = _files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final oldFile = _files[index];
      final nextVersion = oldFile.currentVersion + 1;
      final updatedFile = oldFile.copyWith(
        name: name,
        description: description,
        versions: [...oldFile.versions, FileVersion(versionNumber: nextVersion, timestamp: DateTime.now())],
        updatedAt: DateTime.now(),
      );

      await _dbService.saveFile(updatedFile);
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
      await _dbService.saveFile(updatedFile);
      _loadFiles();
    }
  }

  Future<void> shareWithUser(String fileId, String userName) async {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index != -1) {
      final updatedFile = _files[index].copyWith(
        isShared: true,
        sharedWith: [..._files[index].sharedWith, userName],
      );
      await _dbService.saveFile(updatedFile);
      _loadFiles();
    }
  }

  Future<void> addComment(String fileId, String text) async {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index != -1) {
      final updatedFile = _files[index].copyWith(
        comments: [..._files[index].comments, FileComment(id: const Uuid().v4(), text: text, timestamp: DateTime.now())],
        updatedAt: DateTime.now(),
      );
      await _dbService.saveFile(updatedFile);
      _loadFiles();
    }
  }

  void setSearchQuery(String query) => { _searchQuery = query, notifyListeners() };
  void setSelectedType(String type) => { _selectedType = type, notifyListeners() };
  void toggleOnlyShared(bool value) => { _showOnlyShared = value, notifyListeners() };

  Future<void> syncData() async {
    await Future.delayed(const Duration(seconds: 2));
    _loadFiles();
  }
}
