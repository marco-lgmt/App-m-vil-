import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/trading_service.dart';
import '../models/trade_operation.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final tradingService = context.watch<TradingService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Trading'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Gráficos'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(tradingService),
          _buildChartsTab(tradingService),
          _buildHistoryTab(tradingService),
        ],
      ),
    );
  }
  
  // Tab 1: Resumen general
  Widget _buildSummaryTab(TradingService service) {
    final operations = service.operations;
    
    // Calcular estadísticas
    final totalOperations = operations.length;
    final closedOperations = operations.where((op) => op.status == TradeStatus.closed).length;
    final winningOperations = operations.where((op) => op.result == TradeResult.win).length;
    final winRate = closedOperations > 0 ? (winningOperations / closedOperations * 100) : 0.0;
    
    // Calcular ganancias/pérdidas
    double totalProfitLoss = 0;
    for (var op in operations) {
      if (op.profitLoss != null) {
        totalProfitLoss += op.profitLoss!;
      }
    }
    
    // Determinar color según balance
    final balanceColor = totalProfitLoss >= 0 ? Colors.green : Colors.red;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de resumen
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen de Rendimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Balance general
                  Row(
                    children: [
                      Icon(
                        totalProfitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: balanceColor,
                        size: 36,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Balance Total',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '\$${totalProfitLoss.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: balanceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // Indicadores principales
                  Row(
                    children: [
                      _buildStatIndicator(
                        'Operaciones',
                        totalOperations.toString(),
                        Icons.swap_horiz,
                      ),
                      _buildStatIndicator(
                        'Ganadas',
                        winningOperations.toString(),
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      _buildStatIndicator(
                        'Tasa de Éxito',
                        '${winRate.toStringAsFixed(1)}%',
                        Icons.analytics,
                        color: winRate > 50 ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Estadísticas por par de activos
          const Text(
            'Rendimiento por Activo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildAssetPerformanceList(operations),
          
          const SizedBox(height: 24),
          
          // Estadísticas por día de la semana
          const Text(
            'Rendimiento por Tiempo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildTimeStats(operations),
        ],
      ),
    );
  }
  
  // Tab 2: Gráficos
  Widget _buildChartsTab(TradingService service) {
    final operations = service.operations;
    
    // Filtrar operaciones cerradas
    final closedOperations = operations
        .where((op) => op.status == TradeStatus.closed)
        .toList();
    
    // Si no hay suficientes datos, mostrar mensaje
    if (closedOperations.length < 3) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay suficientes datos para mostrar gráficos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Realiza más operaciones para ver estadísticas detalladas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Gráfico de rendimiento acumulado
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rendimiento Acumulado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Progreso de balance a lo largo del tiempo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _buildPerformanceLineChart(closedOperations),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Gráfico de tipo de operaciones (COMPRA/VENTA)
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribución de Operaciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Proporción de operaciones de compra y venta',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _buildDirectionPieChart(closedOperations),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('COMPRA', Colors.green),
                      const SizedBox(width: 24),
                      _buildLegendItem('VENTA', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Gráfico de resultados (WIN/LOSS)
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resultados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Proporción de operaciones ganadoras y perdedoras',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _buildResultPieChart(closedOperations),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Ganadas', Colors.green),
                      const SizedBox(width: 24),
                      _buildLegendItem('Perdidas', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Tab 3: Historial
  Widget _buildHistoryTab(TradingService service) {
    final operations = service.operations;
    
    if (operations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay operaciones en el historial',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: operations.length,
      itemBuilder: (context, index) {
        final operation = operations[index];
        return _buildOperationHistoryItem(operation);
      },
    );
  }
  
  // Widgets auxiliares
  
  // Indicador de estadística individual
  Widget _buildStatIndicator(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? Colors.blue,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Lista de rendimiento por activo
  Widget _buildAssetPerformanceList(List<TradeOperation> operations) {
    // Agrupar operaciones por activo
    Map<String, List<TradeOperation>> operationsByAsset = {};
    
    for (var op in operations) {
      if (!operationsByAsset.containsKey(op.assetPair)) {
        operationsByAsset[op.assetPair] = [];
      }
      operationsByAsset[op.assetPair]!.add(op);
    }
    
    // Calcular rendimiento por activo
    List<Map<String, dynamic>> assetPerformance = [];
    
    operationsByAsset.forEach((asset, ops) {
      double profitLoss = 0;
      int wins = 0;
      
      for (var op in ops) {
        if (op.profitLoss != null) {
          profitLoss += op.profitLoss!;
        }
        if (op.result == TradeResult.win) {
          wins++;
        }
      }
      
      double winRate = ops.isNotEmpty ? (wins / ops.length * 100) : 0;
      
      assetPerformance.add({
        'asset': asset,
        'profitLoss': profitLoss,
        'operations': ops.length,
        'winRate': winRate,
      });
    });
    
    // Ordenar por rentabilidad
    assetPerformance.sort((a, b) => b['profitLoss'].compareTo(a['profitLoss']));
    
    // Construir lista
    return Column(
      children: assetPerformance.map((data) {
        final isPositive = data['profitLoss'] >= 0;
        final color = isPositive ? Colors.green : Colors.red;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Par de activos
                Expanded(
                  flex: 2,
                  child: Text(
                    data['asset'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Número de operaciones
                Expanded(
                  flex: 1,
                  child: Text(
                    '${data['operations']} ops',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                // Tasa de ganancia
                Expanded(
                  flex: 1,
                  child: Text(
                    '${data['winRate'].toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: data['winRate'] > 50 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                
                // Ganancias/pérdidas
                Expanded(
                  flex: 1,
                  child: Text(
                    '\$${data['profitLoss'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  // Estadísticas por tiempo
  Widget _buildTimeStats(List<TradeOperation> operations) {
    // En una implementación real, aquí analizaríamos tendencias por día/hora
    // Para simplificar, mostramos un mensaje informativo
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.access_time,
              size: 48,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Análisis de Patrones Temporales',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Realiza más operaciones para ver patrones de rendimiento por día y hora',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  
  // Elemento de historial de operación
  Widget _buildOperationHistoryItem(TradeOperation operation) {
    final isOpen = operation.status == TradeStatus.open;
    
    Color statusColor;
    IconData statusIcon;
    
    if (isOpen) {
      statusColor = Colors.blue;
      statusIcon = Icons.timelapse;
    } else if (operation.result == TradeResult.win) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (operation.result == TradeResult.loss) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (operation.result == TradeResult.tie) {
      statusColor = Colors.orange;
      statusIcon = Icons.remove_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_center;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Ícono de estado
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Detalles de la operación
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        operation.assetPair,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${operation.direction} • \$${operation.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: operation.direction == 'COMPRA' ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Resultado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isOpen && operation.profitLoss != null)
                      Text(
                        (operation.profitLoss! >= 0 ? '+' : '') +
                            '\$${operation.profitLoss!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: operation.profitLoss! >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    Text(
                      isOpen
                          ? 'En Curso'
                          : operation.result == TradeResult.win
                              ? 'Ganada'
                              : operation.result == TradeResult.loss
                                  ? 'Perdida'
                                  : 'Empate',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Entrada: ${_formatDateTime(operation.entryTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.timer,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Duración: ${(operation.duration.inSeconds / 60).round()} min',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Gráfico de línea para rendimiento acumulado
  Widget _buildPerformanceLineChart(List<TradeOperation> operations) {
    if (operations.isEmpty) return Container();
    
    // Ordenar por fecha
    operations.sort((a, b) => a.entryTime.compareTo(b.entryTime));
    
    // Calcular balance acumulativo
    List<FlSpot> spots = [];
    double accumulatedBalance = 0;
    
    for (int i = 0; i < operations.length; i++) {
      if (operations[i].profitLoss != null) {
        accumulatedBalance += operations[i].profitLoss!;
        spots.add(FlSpot(i.toDouble(), accumulatedBalance));
      }
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: accumulatedBalance >= 0 ? Colors.green : Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: accumulatedBalance >= 0
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '\$${value.toInt()}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
  
  // Gráfico de pastel para dirección (COMPRA/VENTA)
  Widget _buildDirectionPieChart(List<TradeOperation> operations) {
    // Contar operaciones de compra y venta
    int buyCount = operations.where((op) => op.direction == 'COMPRA').length;
    int sellCount = operations.where((op) => op.direction == 'VENTA').length;
    
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: buyCount.toDouble(),
            title: buyCount.toString(),
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.red,
            value: sellCount.toDouble(),
            title: sellCount.toString(),
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Gráfico de pastel para resultados (WIN/LOSS)
  Widget _buildResultPieChart(List<TradeOperation> operations) {
    // Contar operaciones ganadoras y perdedoras
    int winCount = operations.where((op) => op.result == TradeResult.win).length;
    int lossCount = operations.where((op) => op.result == TradeResult.loss).length;
    
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: winCount.toDouble(),
            title: winCount.toString(),
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.red,
            value: lossCount.toDouble(),
            title: lossCount.toString(),
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Elemento de leyenda para gráficos
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
  
  // Formatear fecha y hora
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}