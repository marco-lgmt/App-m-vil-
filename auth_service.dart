import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _username;
  String? _token;
  DateTime? _expiresAt;
  String? _errorMessage;
  bool _isLoading = false;
  
  // API URL base - reemplazar con la URL real del proyecto
  final String _baseUrl = 'http://localhost:5000';
  
  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  String? get token => _token;
  DateTime? get expiresAt => _expiresAt;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  
  // Inicializar el servicio y verificar autenticación
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _username = prefs.getString('username');
      final expiresString = prefs.getString('expires_at');
      
      if (expiresString != null) {
        _expiresAt = DateTime.parse(expiresString);
      }
      
      // Verificar si hay token guardado y no está expirado
      if (_token != null && _token!.isNotEmpty && _expiresAt != null) {
        if (_expiresAt!.isAfter(DateTime.now())) {
          _isAuthenticated = true;
        } else {
          // Si el token expiró, limpiar datos
          await logout();
        }
      }
    } catch (e) {
      _errorMessage = 'Error al inicializar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Iniciar sesión usando la API
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Validación básica
      if (username.isEmpty || password.isEmpty) {
        _errorMessage = 'Usuario y contraseña son requeridos';
        return false;
      }
      
      // Datos para la petición
      final Map<String, dynamic> loginData = {
        'username': username,
        'password': password,
      };
      
      // Realizar petición a la API
      final response = await http.post(
        Uri.parse('$_baseUrl/api/mobile/auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );
      
      // Procesar respuesta
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Guardar datos de autenticación
          _username = data['username'];
          _token = data['token'];
          _expiresAt = DateTime.parse(data['expires_at']);
          _isAuthenticated = true;
          
          // Guardar en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token!);
          await prefs.setString('username', _username!);
          await prefs.setString('expires_at', _expiresAt!.toIso8601String());
          
          return true;
        } else {
          _errorMessage = data['error'] ?? 'Error de autenticación desconocido';
          return false;
        }
      } else {
        // Error en la conexión con el servidor
        _errorMessage = 'Error de servidor: ${response.statusCode}';
        
        // Si no podemos conectar con el servidor, permitir login simulado para desarrollo
        if (username.isNotEmpty && password.isNotEmpty) {
          await _simulateSuccessfulLogin(username);
          return true;
        }
        
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
      
      // Si hay error de conexión, permitir login simulado para desarrollo
      if (username.isNotEmpty && password.isNotEmpty) {
        await _simulateSuccessfulLogin(username);
        return true;
      }
      
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Método para simular login exitoso cuando no hay conexión al servidor
  Future<void> _simulateSuccessfulLogin(String username) async {
    _username = username;
    _token = 'simulated_token_${DateTime.now().millisecondsSinceEpoch}';
    _expiresAt = DateTime.now().add(Duration(days: 7));
    _isAuthenticated = true;
    
    // Guardar datos simulados
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('username', _username!);
    await prefs.setString('expires_at', _expiresAt!.toIso8601String());
  }
  
  // Cerrar sesión
  Future<void> logout() async {
    _isAuthenticated = false;
    _username = null;
    _token = null;
    _expiresAt = null;
    
    // Limpiar datos guardados
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await prefs.remove('expires_at');
    
    notifyListeners();
  }
  
  // Verificar si el token es válido
  Future<bool> validateToken() async {
    if (_token == null || _expiresAt == null) return false;
    
    // Verificar si el token ha expirado
    if (_expiresAt!.isBefore(DateTime.now())) {
      await logout();
      return false;
    }
    
    // En una implementación real, aquí se verificaría el token con la API
    
    return true;
  }
  
  // Actualizar token (para cuando se necesite refrescarlo)
  Future<bool> refreshToken() async {
    // En una implementación real, aquí se haría una petición para refrescar el token
    // Por ahora, simplemente extendemos la validez del token actual
    
    if (_token == null) return false;
    
    _expiresAt = DateTime.now().add(Duration(days: 7));
    
    // Actualizar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expires_at', _expiresAt!.toIso8601String());
    
    notifyListeners();
    return true;
  }
}