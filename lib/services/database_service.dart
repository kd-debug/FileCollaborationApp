import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class DatabaseService {
  static const String _boxName = 'usersBoxV2'; // V2 to distinguish from previous attempts

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Future<void> clearAllData() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }

  Future<int> registerUser(UserModel user) async {
    final box = Hive.box(_boxName);
    
    // Check if username already exists
    final exists = box.values.any((u) {
      final map = Map<String, dynamic>.from(u);
      return map['username'] == user.username;
    });

    if (exists) {
      throw Exception("Username already exists");
    }

    final id = box.length + 1;
    await box.put(id, {
      'id': id,
      'username': user.username,
      'password': user.password,
    });
    return id;
  }

  Future<UserModel?> loginUser(String username, String password) async {
    final box = Hive.box(_boxName);
    try {
      final userData = box.values.firstWhere(
        (u) {
          final map = Map<String, dynamic>.from(u);
          return map['username'] == username && map['password'] == password;
        },
        orElse: () => null,
      );

      if (userData != null) {
        return UserModel.fromMap(Map<String, dynamic>.from(userData));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final box = Hive.box(_boxName);
    return box.values.map((u) => UserModel.fromMap(Map<String, dynamic>.from(u))).toList();
  }
}
