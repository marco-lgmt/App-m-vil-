class TradeOperation {
  final int id;
  final String assetPair;
  final String direction;
  final double amount;
  final DateTime entryTime;
  final Duration duration;
  final TradeStatus status;
  final TradeResult? result;
  final double? profitLoss;
  
  TradeOperation({
    required this.id,
    required this.assetPair,
    required this.direction,
    required this.amount,
    required this.entryTime,
    required this.duration,
    required this.status,
    this.result,
    this.profitLoss,
  });
  
  // Método para crear una copia con atributos actualizados
  TradeOperation copyWith({
    int? id,
    String? assetPair,
    String? direction,
    double? amount,
    DateTime? entryTime,
    Duration? duration,
    TradeStatus? status,
    TradeResult? result,
    double? profitLoss,
  }) {
    return TradeOperation(
      id: id ?? this.id,
      assetPair: assetPair ?? this.assetPair,
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
      entryTime: entryTime ?? this.entryTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      result: result ?? this.result,
      profitLoss: profitLoss ?? this.profitLoss,
    );
  }
  
  // Método para calcular tiempo restante
  Duration getRemainingTime() {
    final expiryTime = entryTime.add(duration);
    final now = DateTime.now();
    
    if (now.isAfter(expiryTime) || status != TradeStatus.open) {
      return Duration.zero;
    }
    
    return expiryTime.difference(now);
  }
  
  // Método para obtener color de resultado
  String get resultColor {
    if (result == null) return '#757575'; // Gris
    
    switch (result) {
      case TradeResult.win:
        return '#4CAF50'; // Verde
      case TradeResult.loss:
        return '#F44336'; // Rojo
      case TradeResult.tie:
        return '#FFC107'; // Amarillo
    }
  }
  
  // Método para obtener la hora de expiración formateada
  String get expiryTimeFormatted {
    final expiryTime = entryTime.add(duration);
    return '${expiryTime.hour.toString().padLeft(2, '0')}:${expiryTime.minute.toString().padLeft(2, '0')}:${expiryTime.second.toString().padLeft(2, '0')}';
  }
}

enum TradeStatus {
  open,
  closed,
  cancelled,
}

enum TradeResult {
  win,
  loss,
  tie,
}