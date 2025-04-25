import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trading_signal.dart';
import 'auth_service.dart';

class SignalService extends ChangeNotifier {
  List<TradingSignal> _signals = [];
  bool _loading = false;
  String? _error;
  bool _usingLocalGenerator = false;
  
  // API URL base - reemplazar con la URL real del proyecto
  final String _baseUrl = 'http://localhost:5000';
  
  // Getters
  List<TradingSignal> get signals => _signals;
  bool get loading => _loading;
  String? get error => _error;
  bool get usingLocalGenerator => _usingLocalGenerator;
  
  // Obtener señales recientes
  Future<void> fetchSignals({String? marketType}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Construir URL con parámetros opcionales
      String url = '$_baseUrl/api/mobile/signals';
      if (marketType != null) {
        url += '?market_type=$marketType';
      }
      
      // Obtener token de autenticación
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Construir headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // Realizar petición
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['signals'];
          _signals = data.map((item) => TradingSignal.fromJson(item)).toList();
          _usingLocalGenerator = responseData['using_local_generator'] ?? false;
          _error = null;
        } else {
          _error = responseData['error'] ?? 'Error desconocido';
          _generateLocalSignals(marketType: marketType);
        }
      } else {
        _error = 'Error al cargar señales: ${response.statusCode}';
        _generateLocalSignals(marketType: marketType);
      }
    } catch (e) {
      _error = 'Error al conectar con el servidor: $e';
      _generateLocalSignals(marketType: marketType);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // Generar señales nuevas específicas
  Future<void> generateSignals({String marketType = 'OTC', int limit = 3}) async {
    _loading = true;
    notifyListeners();
    
    try {
      // Obtener token de autenticación
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Se requiere autenticación');
      }
      
      // Datos para la petición
      final Map<String, dynamic> requestData = {
        'market_type': marketType,
        'count': limit,
        'token': token,
      };
      
      // Realizar petición
      final response = await http.post(
        Uri.parse('$_baseUrl/api/mobile/generate-signals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['signals'];
          final newSignals = data.map((item) => TradingSignal.fromJson(item)).toList();
          
          // Verificar si estamos usando generador local o API
          _usingLocalGenerator = responseData['using_local_generator'] ?? false;
          
          // Añadir nuevas señales al inicio de la lista
          _signals = [...newSignals, ..._signals];
          _error = null;
        } else {
          _error = responseData['error'] ?? 'Error desconocido';
          _generateLocalSignals(marketType: marketType, count: limit);
        }
      } else {
        _error = 'Error al generar señales: ${response.statusCode}';
        _generateLocalSignals(marketType: marketType, count: limit);
      }
    } catch (e) {
      _error = 'Error al conectar con el servidor: $e';
      _generateLocalSignals(marketType: marketType, count: limit);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // Método simplificado para generar señales OTC específicas (para compatibilidad)
  Future<void> generateOTCSignals(int limit) async {
    await generateSignals(marketType: 'OTC', limit: limit);
  }
  
  // Generar señales locales (cuando la API no está disponible)
  void _generateLocalSignals({String? marketType, int count = 5}) {
    List<TradingSignal> newSignals = [];
    
    // Listas de pares por tipo de mercado
    final Map<String, List<String>> pairsByType = {
      'OTC': ['OTC_EUR/USD', 'OTC_GBP/USD', 'OTC_AUD/USD', 'OTC_USD/JPY'],
      'FOREX': ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD'],
      'CRYPTO': ['BTC/USD', 'ETH/USD', 'LTC/USD', 'XRP/USD'],
    };
    
    // Si se especifica un tipo de mercado, solo usar esos pares
    List<String> availablePairs = [];
    if (marketType != null && pairsByType.containsKey(marketType)) {
      availablePairs = pairsByType[marketType]!;
    } else {
      // Si no se especifica, combinar todos los pares
      pairsByType.forEach((key, value) {
        availablePairs.addAll(value);
      });
    }
    
    // Determinar el tipo de mercado para cada señal
    String getMarketType(String pair) {
      if (pair.startsWith('OTC_')) return 'OTC';
      if (['BTC', 'ETH', 'LTC', 'XRP'].any((crypto) => pair.contains(crypto))) return 'CRYPTO';
      return 'FOREX';
    }
    
    // Generar señales
    for (int i = 0; i < count; i++) {
      final now = DateTime.now();
      final String pair = availablePairs[i % availablePairs.length];
      final String mktType = marketType ?? getMarketType(pair);
      final String entryTime = '${now.hour}:${(now.minute + i + 1) % 60}:00';
      
      newSignals.add(
        TradingSignal(
          id: 1000 + i, // IDs ficticios para señales locales
          assetPair: pair,
          marketType: mktType,
          direction: i % 2 == 0 ? 'COMPRA' : 'VENTA',
          entryTime: entryTime,
          duration: 120 + (i * 60), // Entre 2-7 minutos
          probabilityScore: 0.5 + (i * 0.1) % 0.5, // Entre 0.5-0.95
          confidenceLevel: i % 3 == 0 ? 'ALTA' : (i % 3 == 1 ? 'MEDIA' : 'BAJA'),
          volatility: i % 2 == 0 ? 'media' : (i % 4 == 0 ? 'alta' : 'baja'),
          analysisSummary: 'Señal generada localmente como respaldo. No hay conexión con el servidor.',
          createdAt: DateTime.now(),
        ),
      );
    }
    
    // Si es un market_type específico y ya tenemos señales, filtrar las existentes
    if (marketType != null && _signals.isNotEmpty) {
      final existingSignals = _signals.where((s) => s.marketType == marketType).toList();
      _signals = [...newSignals, ...existingSignals];
    } else {
      // Si no hay filtro o no hay señales, simplemente añadir las nuevas
      _signals = marketType == null
          ? [...newSignals, ..._signals]
          : newSignals;
    }
    
    // Marcar que estamos usando generador local
    _usingLocalGenerator = true;
  }
  
  // Limpiar señales
  void clearSignals() {
    _signals = [];
    notifyListeners();
  }
}