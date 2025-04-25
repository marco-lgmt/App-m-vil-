import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trading_signal.dart';
import '../services/trading_service.dart';

class SignalDetailScreen extends StatefulWidget {
  final TradingSignal signal;
  
  const SignalDetailScreen({
    Key? key, 
    required this.signal,
  }) : super(key: key);

  @override
  _SignalDetailScreenState createState() => _SignalDetailScreenState();
}

class _SignalDetailScreenState extends State<SignalDetailScreen> {
  bool _isExpanded = false;
  bool _operationInProgress = false;
  
  @override
  Widget build(BuildContext context) {
    final tradingService = Provider.of<TradingService>(context);
    
    // Calcular el color según la dirección
    final directionColor = widget.signal.direction == 'COMPRA' ? Colors.green : Colors.red;
    
    // Determinar el emoji según el nivel de confianza
    final confidenceIcon = widget.signal.confidenceEmoji;
    
    // Calcular tiempo restante para operar
    final currentTime = DateTime.now();
    final entryTime = _parseEntryTime(widget.signal.entryTime);
    final expiryTime = entryTime.add(Duration(seconds: widget.signal.duration));
    final isTimeValid = currentTime.isBefore(expiryTime);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Señal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implementación futura: compartir señal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función de compartir en desarrollo')),
              );
            },
            tooltip: 'Compartir Señal',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta principal con información de la señal
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: directionColor,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado: Par y Dirección
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.signal.assetPair,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
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
                                widget.signal.marketType,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: directionColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.signal.direction,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: directionColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Indicadores principales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildIndicator(
                          'Hora de Entrada',
                          widget.signal.entryTime,
                          Icons.access_time,
                          isTimeValid ? Colors.blue : Colors.grey,
                        ),
                        _buildIndicator(
                          'Duración',
                          '${widget.signal.durationMinutes} min',
                          Icons.timer,
                          Colors.orange,
                        ),
                        _buildIndicator(
                          'Confianza',
                          '${confidenceIcon} ${widget.signal.confidenceLevel}',
                          Icons.verified,
                          _getConfidenceColor(widget.signal.confidenceLevel),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Indicadores secundarios
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildIndicator(
                          'Probabilidad',
                          '${(widget.signal.probabilityScore * 100).round()}%',
                          Icons.analytics,
                          _getProbabilityColor(widget.signal.probabilityScore),
                        ),
                        _buildIndicator(
                          'Volatilidad',
                          widget.signal.volatility.toUpperCase(),
                          Icons.trending_up,
                          _getVolatilityColor(widget.signal.volatility),
                        ),
                        _buildIndicator(
                          'Creación',
                          _getTimeAgo(widget.signal.createdAt),
                          Icons.calendar_today,
                          Colors.grey,
                        ),
                      ],
                    ),
                    
                    if (widget.signal.analysisSummary.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      // Resumen del análisis
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Resumen del Análisis',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                                onPressed: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                                tooltip: _isExpanded ? 'Mostrar menos' : 'Mostrar más',
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: Text(
                              widget.signal.analysisSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(widget.signal.analysisSummary),
                            crossFadeState: _isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Indicador de tiempo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isTimeValid
                  ? _buildTimeRemainingCard(expiryTime)
                  : _buildExpiredTimeCard(),
            ),
            
            const SizedBox(height: 24),
            
            // Tarjeta de operación
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ejecutar Operación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Monto de operación
                    Row(
                      children: [
                        const Text(
                          'Monto:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: tradingService.tradeAmount,
                            min: 5,
                            max: 100,
                            divisions: 19,
                            label: '\$${tradingService.tradeAmount.toStringAsFixed(0)}',
                            onChanged: (value) {
                              tradingService.setTradeAmount(value);
                            },
                          ),
                        ),
                        Text(
                          '\$${tradingService.tradeAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Trading automático
                    SwitchListTile(
                      title: const Text('Trading Automático'),
                      subtitle: const Text('Ejecutar automáticamente según la estrategia'),
                      value: tradingService.autoTrading,
                      onChanged: (value) {
                        tradingService.setAutoTrading(value);
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Botones de operación
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _operationInProgress || !isTimeValid
                                ? null
                                : () => _executeTrade(context, tradingService, 'COMPRA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _operationInProgress
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('COMPRA'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _operationInProgress || !isTimeValid
                                ? null
                                : () => _executeTrade(context, tradingService, 'VENTA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _operationInProgress
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('VENTA'),
                          ),
                        ),
                      ],
                    ),
                    
                    if (!isTimeValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'El tiempo de entrada para esta señal ha expirado',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  // Ejecutar operación
  Future<void> _executeTrade(
    BuildContext context,
    TradingService tradingService,
    String direction,
  ) async {
    setState(() {
      _operationInProgress = true;
    });
    
    try {
      // Crear copia de la señal con la dirección actualizada si es necesario
      final signalToUse = direction == widget.signal.direction
          ? widget.signal
          : TradingSignal(
              id: widget.signal.id,
              assetPair: widget.signal.assetPair,
              marketType: widget.signal.marketType,
              direction: direction, // Usamos la dirección seleccionada
              entryTime: widget.signal.entryTime,
              duration: widget.signal.duration,
              probabilityScore: widget.signal.probabilityScore,
              confidenceLevel: widget.signal.confidenceLevel,
              volatility: widget.signal.volatility,
              analysisSummary: widget.signal.analysisSummary,
              createdAt: widget.signal.createdAt,
            );
      
      // Ejecutar la operación
      final result = await tradingService.executeTrade(signalToUse);
      
      // Mostrar resultado
      if (mounted) {
        _showResultDialog(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ejecutar operación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _operationInProgress = false;
        });
      }
    }
  }
  
  // Mostrar diálogo con resultado de operación
  void _showResultDialog(BuildContext context, operation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          operation.result == TradeResult.win ? '¡Operación Exitosa!' : 'Operación Perdida',
          style: TextStyle(
            color: operation.result == TradeResult.win ? Colors.green : Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              operation.result == TradeResult.win ? Icons.check_circle : Icons.cancel,
              color: operation.result == TradeResult.win ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              operation.result == TradeResult.win
                  ? 'Has ganado ${operation.profitLoss!.toStringAsFixed(2)}'
                  : 'Has perdido ${(-operation.profitLoss!).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${operation.assetPair} - ${operation.direction}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver a Señales'),
          ),
        ],
      ),
    );
  }
  
  // Widget para mostrar indicadores
  Widget _buildIndicator(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  // Widget para mostrar tiempo restante
  Widget _buildTimeRemainingCard(DateTime expiryTime) {
    final remaining = expiryTime.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return Card(
      elevation: 2,
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiempo Restante para Operar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$minutes min $seconds seg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para mostrar tiempo expirado
  Widget _buildExpiredTimeCard() {
    return Card(
      elevation: 2,
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.timer_off,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo de Entrada Expirado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Esta señal ya no está activa',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Parsear hora de entrada
  DateTime _parseEntryTime(String timeString) {
    final now = DateTime.now();
    final parts = timeString.split(':');
    
    if (parts.length < 2) return now;
    
    int hour = int.tryParse(parts[0]) ?? now.hour;
    int minute = int.tryParse(parts[1]) ?? now.minute;
    int second = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    
    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      second,
    );
  }
  
  // Obtener hace cuánto tiempo se creó la señal
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min';
    } else {
      return 'Ahora';
    }
  }
  
  // Obtener color según nivel de confianza
  Color _getConfidenceColor(String level) {
    switch (level) {
      case 'ALTA':
        return Colors.green;
      case 'MEDIA':
        return Colors.orange;
      case 'BAJA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  // Obtener color según probabilidad
  Color _getProbabilityColor(double probability) {
    if (probability >= 0.7) {
      return Colors.green;
    } else if (probability >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Obtener color según volatilidad
  Color _getVolatilityColor(String volatility) {
    switch (volatility.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}