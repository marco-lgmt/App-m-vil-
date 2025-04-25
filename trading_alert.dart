enum AlertType {
  price,   // Alerta basada en precio
  signal,  // Alerta basada en señal de trading
  news,    // Alerta basada en noticias económicas
}

class TradingAlert {
  final String id;
  final String title;
  final String description;
  final AlertType type;
  final Map<String, dynamic> condition;
  final bool enabled;
  final DateTime createdAt;
  
  TradingAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.condition,
    required this.enabled,
    required this.createdAt,
  });
  
  // Constructor para crear desde JSON
  factory TradingAlert.fromJson(Map<String, dynamic> json) {
    return TradingAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: _parseAlertType(json['type']),
      condition: json['condition'],
      enabled: json['enabled'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,  // Convertir enum a string
      'condition': condition,
      'enabled': enabled,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  // Crear una copia con cambios
  TradingAlert copyWith({
    String? id,
    String? title,
    String? description,
    AlertType? type,
    Map<String, dynamic>? condition,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return TradingAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      condition: condition ?? Map.from(this.condition),
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Parsear tipo de alerta
  static AlertType _parseAlertType(String type) {
    switch (type) {
      case 'price':
        return AlertType.price;
      case 'signal':
        return AlertType.signal;
      case 'news':
        return AlertType.news;
      default:
        return AlertType.price;
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool read;
  
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.data,
    this.read = false,
  });
  
  // Constructor para crear desde JSON
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'],
      read: json['read'] ?? false,
    );
  }
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'read': read,
    };
  }
  
  // Marcar como leída
  NotificationItem markAsRead() {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      data: data,
      read: true,
    );
  }
}