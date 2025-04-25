import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trading_signal.dart';
import '../models/trade_operation.dart';

class TradingService extends ChangeNotifier {
  bool _autoTrading = false;
  double _tradeAmount = 10.0;
  List<TradeOperation> _operations = [];
  TradeStrategy _currentStrategy = TradeStrategy.moderate;
  
  // Estadísticas de trading
  int _totalTrades = 0;
  int _winningTrades = 0;
  double _balance = 0.0;
  
  bool get autoTrading => _autoTrading;
  double get tradeAmount => _tradeAmount;
  List<TradeOperation> get operations => _operations;
  TradeStrategy get currentStrategy => _currentStrategy;
  int get totalTrades => _totalTrades;
  int get winningTrades => _winningTrades;
  double get winRate => _totalTrades > 0 ? (_winningTrades / _totalTrades) * 100 : 0;
  double get balance => _balance;
  
  // Inicializar el servicio y cargar configuraciones
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoTrading = prefs.getBool('auto_trading') ?? false;
    _tradeAmount = prefs.getDouble('trade_amount') ?? 10.0;
    _currentStrategy = TradeStrategy.values[prefs.getInt('strategy') ?? 1];
    
    // Cargar estadísticas guardadas
    _totalTrades = prefs.getInt('total_trades') ?? 0;
    _winningTrades = prefs.getInt('winning_trades') ?? 0;
    _balance = prefs.getDouble('balance') ?? 0.0;
    
    notifyListeners();
  }
  
  // Activar/desactivar trading automático
  Future<void> setAutoTrading(bool value) async {
    _autoTrading = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_trading', value);
    notifyListeners();
  }
  
  // Cambiar monto de operación
  Future<void> setTradeAmount(double amount) async {
    _tradeAmount = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('trade_amount', amount);
    notifyListeners();
  }
  
  // Cambiar estrategia de trading
  Future<void> setStrategy(TradeStrategy strategy) async {
    _currentStrategy = strategy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('strategy', strategy.index);
    notifyListeners();
  }
  
  // Realizar una operación basada en una señal
  Future<TradeOperation> executeTrade(TradingSignal signal) async {
    // Calcular el monto según la estrategia seleccionada
    final amount = _getAmountForSignal(signal);
    
    // Crear operación (en una implementación real, esto interactuaría con Quotex)
    final operation = TradeOperation(
      id: DateTime.now().millisecondsSinceEpoch,
      assetPair: signal.assetPair,
      direction: signal.direction,
      amount: amount,
      entryTime: DateTime.now(),
      duration: Duration(seconds: signal.duration),
      status: TradeStatus.open,
      result: null,
      profitLoss: null,
    );
    
    // Añadir a la lista de operaciones
    _operations = [operation, ..._operations];
    notifyListeners();
    
    // Simular resultado después de la duración (en una app real esto vendría de Quotex)
    await Future.delayed(Duration(seconds: 5)); // Solo para demo, reducido de signal.duration
    
    // Obtener resultado (en una implementación real, obtendrías esto de Quotex)
    final isWin = signal.probabilityScore > 0.5;
    final profitLoss = isWin ? amount * 0.85 : -amount;
    
    // Actualizar operación
    final updatedOperation = operation.copyWith(
      status: TradeStatus.closed,
      result: isWin ? TradeResult.win : TradeResult.loss,
      profitLoss: profitLoss,
    );
    
    // Actualizar lista de operaciones
    final index = _operations.indexWhere((op) => op.id == operation.id);
    if (index != -1) {
      _operations[index] = updatedOperation;
    }
    
    // Actualizar estadísticas
    _totalTrades++;
    if (isWin) _winningTrades++;
    _balance += profitLoss;
    
    // Guardar estadísticas
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_trades', _totalTrades);
    await prefs.setInt('winning_trades', _winningTrades);
    await prefs.setDouble('balance', _balance);
    
    notifyListeners();
    return updatedOperation;
  }
  
  // Calcular monto según la estrategia y nivel de confianza
  double _getAmountForSignal(TradingSignal signal) {
    switch (_currentStrategy) {
      case TradeStrategy.conservative:
        // Solo opera con señales de alta confianza con monto base
        if (signal.confidenceLevel == 'ALTA') {
          return _tradeAmount;
        }
        return 0; // No operar con señales de baja confianza
        
      case TradeStrategy.moderate:
        // Opera con todas las señales, pero ajusta el monto según la confianza
        if (signal.confidenceLevel == 'ALTA') {
          return _tradeAmount;
        } else if (signal.confidenceLevel == 'MEDIA') {
          return _tradeAmount * 0.7;
        } else {
          return _tradeAmount * 0.5;
        }
        
      case TradeStrategy.aggressive:
        // Opera con todas las señales, aumentando montos en alta confianza
        if (signal.confidenceLevel == 'ALTA') {
          return _tradeAmount * 1.5;
        } else if (signal.confidenceLevel == 'MEDIA') {
          return _tradeAmount;
        } else {
          return _tradeAmount * 0.7;
        }
    }
  }
  
  // Limpiar historial de operaciones
  Future<void> clearOperations() async {
    _operations = [];
    notifyListeners();
  }
}

enum TradeStrategy {
  conservative,
  moderate,
  aggressive,
}