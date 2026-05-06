import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/file_model.dart';

class DatabaseService {
  static const String _boxName = 'jsonStoreBox';
  static const String _dbKey = 'app_database_json';
  static const String _serverUrl = 'http://localhost:8080';

  Future<void> init() async {
    await Hive.openBox(_boxName);
    if (!Hive.box(_boxName).containsKey(_dbKey)) {
      final initialData = {'users': [], 'files': []};
      await Hive.box(_boxName).put(_dbKey, jsonEncode(initialData));
      _syncToDisk(initialData);
    }
  }

  // This function sends the data to our local server to write the .json file
  Future<void> _syncToDisk(Map<String, dynamic> data) async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await http.post(Uri.parse(_serverUrl), body: jsonStr);
    } catch (e) {
      print('Local server not running. Start it with: dart lib/services/local_server.dart');
    }
  }

  Map<String, dynamic> _readDb() {
    final box = Hive.box(_boxName);
    return jsonDecode(box.get(_dbKey));
  }

  Future<void> _writeDb(Map<String, dynamic> data) async {
    final box = Hive.box(_boxName);
    await box.put(_dbKey, jsonEncode(data));
    await _syncToDisk(data);
  }

  Future<void> registerUser(UserModel user) async {
    final db = _readDb();
    final List users = db['users'];
    if (users.any((u) => u['username'] == user.username)) throw Exception('User exists');
    users.add(user.toMap());
    await _writeDb(db);
  }

  Future<UserModel?> loginUser(String username, String password) async {
    final db = _readDb();
    final List users = db['users'];
    final userData = users.firstWhere((u) => u['username'] == username && u['password'] == password, orElse: () => null);
    return userData != null ? UserModel.fromMap(userData) : null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = _readDb();
    return (db['users'] as List).map((u) => UserModel.fromMap(u)).toList();
  }

  Future<void> saveFile(FileModel file) async {
    final db = _readDb();
    final List files = db['files'];
    final index = files.indexWhere((f) => f['id'] == file.id);
    if (index != -1) files[index] = file.toMap(); else files.add(file.toMap());
    await _writeDb(db);
  }

  List<FileModel> getAllFiles() {
    final db = _readDb();
    return (db['files'] as List).map((f) => FileModel.fromMap(f)).toList();
  }
}
