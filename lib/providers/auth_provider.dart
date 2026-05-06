import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<String?> register(String username, String password) async {
    try {
      await _dbService.registerUser(UserModel(username: username, password: password));
      return null; // Success
    } catch (e) {
      if (e.toString().contains("Username already exists")) {
        return "Username already exists.";
      }
      return "Database error: ${e.toString()}";
    }
  }

  Future<bool> login(String username, String password) async {
    final user = await _dbService.loginUser(username, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<List<UserModel>> getOtherUsers() async {
    final allUsers = await _dbService.getAllUsers();
    // Return all users except the current one for sharing simulation
    return allUsers.where((u) => u.id != _currentUser?.id).toList();
  }
}
