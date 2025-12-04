import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUsername = 'username';
  static const String _keyFullName = 'fullName';
  static const String _keyRole = 'role';

  
  static final List<User> _defaultUsers = [
  User(
      username: 'Bina Marga Kotim',
      password: 'binamarga2425',
      fullName: 'Bina Marga Kotim',
      role: 'user',
    ),
    User(
      username: 'Lab Teknik',
      password: 'Lab1225',
      fullName: 'Lab Teknik',
      role: 'user',
    ),
    User(
      username: 'Dinas PU Kotim',
      password: 'dsdabmbkprkp25',
      fullName: 'Dinas PU Kotim',
      role: 'user',
    ),
  ];




 
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
     
      print('Login attempt - Username: $username, Password: $password');
      
      
      final user = _defaultUsers.firstWhere(
        (u) => u.username.trim().toLowerCase() == username.trim().toLowerCase() && 
               u.password == password,
        orElse: () => User(username: '', password: '', fullName: '', role: ''),
      );

      if (user.username.isEmpty) {
        return {
          'success': false,
          'message': 'Username atau password salah',
        };
      }

      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUsername, user.username);
      await prefs.setString(_keyFullName, user.fullName);
      await prefs.setString(_keyRole, user.role);

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
}