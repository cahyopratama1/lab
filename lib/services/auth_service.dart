import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUsername = 'username';
  static const String _keyFullName = 'fullName';
  static const String _keyRole = 'role';

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      
      final user = await _dbHelper.loginUser(username, password);

      if (user == null) {
        return {
          'success': false,
          'message': 'Username atau password salah',
        };
      }

      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUsername, user['username']);
      await prefs.setString(_keyFullName, user['fullName']);
      await prefs.setString(_keyRole, user['role']);

      return {
        'success': true,
        'message': 'Login berhasil',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyRole);
  }

  
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  
  Future<Map<String, String?>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_keyUsername),
      'fullName': prefs.getString(_keyFullName),
      'role': prefs.getString(_keyRole),
    };
  }
  
  
  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  

 
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String fullName,
    String role = 'user',
  }) async {
    try {
     
      final existing = await _dbHelper.getUserByUsername(username);
      if (existing != null) {
        return {
          'success': false,
          'message': 'Username sudah digunakan',
        };
      }

      
      await _dbHelper.addUser(
        username: username,
        password: password,
        fullName: fullName,
        role: role,
      );

      return {
        'success': true,
        'message': 'Registrasi berhasil',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal registrasi: $e',
      };
    }
  }

 
  Future<Map<String, dynamic>> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      
      final user = await _dbHelper.loginUser(username, oldPassword);
      if (user == null) {
        return {
          'success': false,
          'message': 'Password lama salah',
        };
      }

      
      await _dbHelper.updateUser(username: username, password: newPassword);

      return {
        'success': true,
        'message': 'Password berhasil diubah',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengubah password: $e',
      };
    }
  }

 
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _dbHelper.getAllUsers();
  }

  
  Future<Map<String, dynamic>> deleteUser(String username) async {
    try {
      await _dbHelper.deleteUser(username);
      return {
        'success': true,
        'message': 'User berhasil dihapus',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menghapus user: $e',
      };
    }
  }
}