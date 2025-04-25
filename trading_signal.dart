class TradingSignal {
  final int id;
  final String assetPair;
  final String marketType;
  final String direction;
  final String entryTime;
  final int duration;
  final double probabilityScore;
  final String confidenceLevel;
  final String volatility;
  final String analysisSummary;
  final DateTime createdAt;
  
  TradingSignal({
    required this.id,
    required this.assetPair,
    required this.marketType,
    required this.direction,
    required this.entryTime,
    required this.duration,
    required this.probabilityScore,
    required this.confidenceLevel,
    required this.volatility,
    required this.analysisSummary,
    required this.createdAt,
  });
  
  // Constructor para crear desde JSON
  factory TradingSignal.fromJson(Map<String, dynamic> json) {
    return TradingSignal(
      id: json['id'],
      assetPair: json['asset_pair'],
      marketType: json['market_type'],
      direction: json['direction'],
      entryTime: json['entry_time'],
      duration: json['duration'],
      probabilityScore: json['probability_score'].toDouble(),
      confidenceLevel: json['confidence_level'],
      volatility: json['volatility'],
      analysisSummary: json['analysis_summary'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_pair': assetPair,
      'market_type': marketType,
      'direction': direction,
      'entry_time': entryTime,
      'duration': duration,
      'probability_score': probabilityScore,
      'confidence_level': confidenceLevel,
      'volatility': volatility,
      'analysis_summary': analysisSummary,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  // Obtener color según nivel de confianza
  String get confidenceColor {
    switch (confidenceLevel) {
      case 'ALTA':
        return '#4CAF50'; // Verde
      case 'MEDIA':
        return '#FFC107'; // Amarillo
      case 'BAJA':
        return '#F44336'; // Rojo
      default:
        return '#FFC107'; // Amarillo por defecto
    }
  }
  
  // Obtener emoji según nivel de confianza
  String get confidenceEmoji {
    switch (confidenceLevel) {
      case 'ALTA':
        return '🟢';
      case 'MEDIA':
        return '🟡';
      case 'BAJA':
        return '🔴';
      default:
        return '🟡';
    }
  }
  
  // Obtener duración en minutos
  int get durationMinutes => (duration / 60).round();
}