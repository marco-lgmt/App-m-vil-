import 'package:flutter/material.dart';
import '../models/trading_signal.dart';

class SignalIndicator extends StatelessWidget {
  final TradingSignal signal;
  
  const SignalIndicator({
    Key? key,
    required this.signal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determinar colores basados en la dirección y confianza
    final directionColor = signal.direction == 'COMPRA' ? Colors.green : Colors.red;
    
    Color confidenceColor;
    switch (signal.confidenceLevel) {
      case 'ALTA':
        confidenceColor = Colors.green;
        break;
      case 'MEDIA':
        confidenceColor = Colors.orange;
        break;
      case 'BAJA':
        confidenceColor = Colors.red;
        break;
      default:
        confidenceColor = Colors.orange;
    }
    
    return Card(
      color: Colors.black.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: directionColor,
          width: 2,
        ),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado con par y dirección
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      signal.assetPair,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        signal.marketType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: directionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    signal.direction,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: directionColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Detalles de la señal
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Entrada',
                    signal.entryTime,
                    Icons.access_time,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Duración',
                    '${signal.durationMinutes} min',
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Confianza',
                    '${signal.confidenceEmoji} ${signal.confidenceLevel}',
                    Icons.verified,
                    color: confidenceColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Resumen del análisis
            if (signal.analysisSummary.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  signal.analysisSummary,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Widget para construir cada elemento de detalle
  Widget _buildDetailItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color ?? Colors.white70,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}