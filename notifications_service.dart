import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trading_alert.dart';
import '../models/trading_signal.dart';
import 'signal_service.dart';

class NotificationsService extends ChangeNotifier {
  List<TradingAlert> _alerts = [];
  List<NotificationItem> _notificationHistory = [];
  
  // Configuración general
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _signalAlertsEnabled = true;
  
  // Getters
  List<TradingAlert> get alerts => _alerts;
  List<NotificationItem> get notificationHistory => _notificationHistory;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get signalAlertsEnabled => _signalAlertsEnabled;
  
  // Inicializar servicio y cargar configuración
  Future<void> init() async {
    await _loadPreferences();
    await _loadAlerts();
    await _loadNotificationHistory();
  }
  
  // Cargar preferencias desde almacenamiento
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _signalAlertsEnabled = prefs.getBool('signal_alerts_enabled') ?? true;
    
    notifyListeners();
  }
  
  // Cargar alertas desde almacenamiento
  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = prefs.getStringList('trading_alerts') ?? [];
    
    _alerts = alertsJson
        .map((json) => TradingAlert.fromJson(jsonDecode(json)))
        .toList();
    
    // Ordenar por fecha de creación (más reciente primero)
    _alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    notifyListeners();
  }
  
  // Cargar historial de notificaciones
  Future<void> _loadNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('notification_history') ?? [];
    
    _notificationHistory = historyJson
        .map((json) => NotificationItem.fromJson(jsonDecode(json)))
        .toList();
    
    // Ordenar por fecha (más reciente primero)
    _notificationHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
  }
  
  // Guardar alertas en almacenamiento
  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = _alerts
        .map((alert) => jsonEncode(alert.toJson()))
        .toList();
    
    await prefs.setStringList('trading_alerts', alertsJson);
  }
  
  // Guardar historial de notificaciones
  Future<void> _saveNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _notificationHistory
        .map((notification) => jsonEncode(notification.toJson()))
        .toList();
    
    await prefs.setStringList('notification_history', historyJson);
  }
  
  // Configurar notificaciones
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }
  
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    notifyListeners();
  }
  
  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    notifyListeners();
  }
  
  Future<void> setSignalAlertsEnabled(bool value) async {
    _signalAlertsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('signal_alerts_enabled', value);
    notifyListeners();
  }
  
  // Gestión de alertas
  Future<void> addAlert(TradingAlert alert) async {
    _alerts.add(alert);
    await _saveAlerts();
    notifyListeners();
  }
  
  Future<void> updateAlert(TradingAlert updatedAlert) async {
    final index = _alerts.indexWhere((alert) => alert.id == updatedAlert.id);
    if (index != -1) {
      _alerts[index] = updatedAlert;
      await _saveAlerts();
      notifyListeners();
    }
  }
  
  Future<void> removeAlert(String alertId) async {
    _alerts.removeWhere((alert) => alert.id == alertId);
    await _saveAlerts();
    notifyListeners();
  }
  
  Future<void> toggleAlert(String alertId, bool enabled) async {
    final index = _alerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(enabled: enabled);
      await _saveAlerts();
      notifyListeners();
    }
  }
  
  // Gestión de notificaciones
  Future<void> addNotification(NotificationItem notification) async {
    _notificationHistory.insert(0, notification);
    
    // Limitar historial a 50 notificaciones
    if (_notificationHistory.length > 50) {
      _notificationHistory = _notificationHistory.sublist(0, 50);
    }
    
    await _saveNotificationHistory();
    notifyListeners();
  }
  
  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notificationHistory.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notificationHistory[index] = _notificationHistory[index].markAsRead();
      await _saveNotificationHistory();
      notifyListeners();
    }
  }
  
  Future<void> clearNotificationHistory() async {
    _notificationHistory = [];
    await _saveNotificationHistory();
    notifyListeners();
  }
  
  // Verificar señales nuevas y enviar notificaciones
  Future<void> checkNewSignals(List<TradingSignal> signals) async {
    if (!_notificationsEnabled || !_signalAlertsEnabled) return;
    
    // Aplicar sólo a nuevas señales (en una implementación real se verificaría)
    final latestSignal = signals.isNotEmpty ? signals.first : null;
    if (latestSignal == null) return;
    
    // Verificar alertas activadas
    for (final alert in _alerts.where((a) => a.enabled && a.type == AlertType.signal)) {
      // Verificar condiciones
      final condition = alert.condition;
      
      // Verificar nivel de confianza
      if (condition['confidence'] == latestSignal.confidenceLevel) {
        // Verificar tipo de mercado
        if (condition['market_type'] == 'ANY' || 
            condition['market_type'] == latestSignal.marketType) {
          // Crear notificación
          final notification = NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Nueva Señal - ${latestSignal.assetPair}',
            message: '${latestSignal.direction} con confianza ${latestSignal.confidenceLevel}',
            type: 'signal',
            timestamp: DateTime.now(),
            data: {
              'signal_id': latestSignal.id,
              'asset_pair': latestSignal.assetPair,
              'direction': latestSignal.direction,
            },
          );
          
          // Añadir al historial
          await addNotification(notification);
          
          // TODO: Mostrar notificación push (requiere implementación específica)
        }
      }
    }
  }
  
  // Verificar precios para alertas
  Future<void> checkPriceAlerts(Map<String, double> currentPrices) async {
    if (!_notificationsEnabled) return;
    
    // Verificar alertas de precio activadas
    for (final alert in _alerts.where((a) => a.enabled && a.type == AlertType.price)) {
      final condition = alert.condition;
      final asset = condition['asset'];
      
      // Verificar si tenemos el precio para este activo
      if (currentPrices.containsKey(asset)) {
        final currentPrice = currentPrices[asset]!;
        final targetPrice = double.tryParse(condition['value'] ?? '0.0') ?? 0.0;
        final direction = condition['direction'];
        
        bool conditionMet = false;
        
        // Verificar si se cumple la condición
        if (direction == 'above' && currentPrice >= targetPrice) {
          conditionMet = true;
        } else if (direction == 'below' && currentPrice <= targetPrice) {
          conditionMet = true;
        }
        
        if (conditionMet) {
          // Crear notificación
          final notification = NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Alerta de Precio - $asset',
            message: 'Precio $currentPrice ha llegado al nivel objetivo $targetPrice',
            type: 'price',
            timestamp: DateTime.now(),
            data: {
              'asset': asset,
              'price': currentPrice,
              'target_price': targetPrice,
              'direction': direction,
            },
          );
          
          // Añadir al historial
          await addNotification(notification);
          
          // TODO: Mostrar notificación push
          
          // Deshabilitar la alerta (solo se activa una vez)
          await toggleAlert(alert.id, false);
        }
      }
    }
  }
}