import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/signal_service.dart';
import '../models/trading_signal.dart';
import 'signal_detail_screen.dart';

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({Key? key}) : super(key: key);

  @override
  _SignalsScreenState createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  String _selectedFilter = 'Todos';
  
  @override
  Widget build(BuildContext context) {
    final signalService = context.watch<SignalService>();
    
    // Filtrar señales según el tipo seleccionado
    List<TradingSignal> filteredSignals = signalService.signals;
    if (_selectedFilter != 'Todos') {
      filteredSignals = signalService.signals
          .where((signal) => signal.marketType == _selectedFilter)
          .toList();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Señales de Trading'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => signalService.fetchSignals(),
            tooltip: 'Actualizar señales',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de tipo de mercado
          _buildFilterChips(),
          
          // Botón para generar nuevas señales OTC
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => signalService.generateOTCSignals(3),
              icon: const Icon(Icons.add_chart),
              label: const Text('Generar Señales OTC'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          
          // Estado de carga
          if (signalService.loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Mensaje de error
          if (signalService.error != null && !signalService.loading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Error al cargar señales',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${signalService.error}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Se están mostrando señales generadas localmente.',
                            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Lista de señales
          Expanded(
            child: filteredSignals.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredSignals.length,
                    itemBuilder: (context, index) {
                      return _buildSignalItem(filteredSignals[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  // Construir filtros de chips
  Widget _buildFilterChips() {
    final filters = ['Todos', 'OTC', 'FOREX', 'CRYPTO'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(filter),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.grey[800],
                selectedColor: Colors.blue,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  // Construir elemento de señal
  Widget _buildSignalItem(TradingSignal signal) {
    final directionColor = signal.direction == 'COMPRA' ? Colors.green : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            // Par de activos
            Text(
              signal.assetPair,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            
            // Tipo de mercado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        subtitle: Row(
          children: [
            // Nivel de confianza con emoji
            Text(
              "${signal.confidenceEmoji} ${signal.confidenceLevel}",
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 8),
            
            // Tiempo de entrada
            const Icon(Icons.access_time, size: 12),
            const SizedBox(width: 2),
            Text(
              signal.entryTime,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
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
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Detalles adicionales
          Row(
            children: [
              _buildDetailItem('Duración', '${signal.durationMinutes} min'),
              _buildDetailItem('Probabilidad', '${(signal.probabilityScore * 100).round()}%'),
              _buildDetailItem('Volatilidad', signal.volatility),
            ],
          ),
          const SizedBox(height: 12),
          
          // Resumen del análisis
          if (signal.analysisSummary.isNotEmpty) ...[
            const Text(
              'Análisis:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                signal.analysisSummary,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
          
          // Botones de acción
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navegar a la pantalla de detalle
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignalDetailScreen(signal: signal),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: directionColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Operar ${signal.direction}'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  // Navegar a la pantalla de gráfico con este par preseleccionado
                  Navigator.pushNamed(context, '/chart');
                  // En un implementación real, pasaríamos el par para preseleccionarlo
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: directionColor),
                ),
                child: const Text('Ver Gráfico'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Construir elemento de detalle
  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Construir estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_cellular_alt,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay señales disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón "Generar Señales OTC" para obtener nuevas señales',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}