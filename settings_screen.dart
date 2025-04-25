import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/trading_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final tradingService = context.watch<TradingService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Sección de perfil
          const SizedBox(height: 16),
          _buildSectionHeader('Perfil de Usuario'),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(authService.username ?? 'Usuario'),
            subtitle: const Text('Cuenta de Quotex'),
          ),
          const Divider(),
          
          // Sección de trading
          _buildSectionHeader('Configuración de Trading'),
          
          // Trading automático
          SwitchListTile(
            value: tradingService.autoTrading,
            onChanged: tradingService.setAutoTrading,
            title: const Text('Trading Automático'),
            subtitle: const Text(
              'Ejecutar operaciones automáticamente basadas en señales recibidas',
            ),
            secondary: const Icon(Icons.auto_awesome),
          ),
          
          // Monto de operación
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Monto de Operación'),
            subtitle: Text('\$${tradingService.tradeAmount.toStringAsFixed(2)}'),
            trailing: DropdownButton<double>(
              value: tradingService.tradeAmount,
              items: [5.0, 10.0, 20.0, 50.0, 100.0].map((amount) {
                return DropdownMenuItem<double>(
                  value: amount,
                  child: Text('\$${amount.toStringAsFixed(0)}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  tradingService.setTradeAmount(value);
                }
              },
            ),
          ),
          
          // Estrategia de trading
          ListTile(
            leading: const Icon(Icons.strategy),
            title: const Text('Estrategia de Trading'),
            subtitle: Text(_getStrategyName(tradingService.currentStrategy)),
            trailing: DropdownButton<TradeStrategy>(
              value: tradingService.currentStrategy,
              items: TradeStrategy.values.map((strategy) {
                return DropdownMenuItem<TradeStrategy>(
                  value: strategy,
                  child: Text(_getStrategyName(strategy)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  tradingService.setStrategy(value);
                }
              },
            ),
          ),
          
          const Divider(),
          
          // Estadísticas
          _buildSectionHeader('Estadísticas de Trading'),
          _buildStatItem(
            'Operaciones Totales',
            '${tradingService.totalTrades}',
            Icons.analytics,
          ),
          _buildStatItem(
            'Tasa de Ganancia',
            '${tradingService.winRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            valueColor: tradingService.winRate > 50 ? Colors.green : Colors.red,
          ),
          _buildStatItem(
            'Balance Total',
            '\$${tradingService.balance.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            valueColor: tradingService.balance >= 0 ? Colors.green : Colors.red,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Limpiar Historial'),
            subtitle: const Text('Eliminar todas las operaciones registradas'),
            trailing: ElevatedButton(
              onPressed: tradingService.clearOperations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Limpiar'),
            ),
          ),
          
          const Divider(),
          
          // Opciones de la aplicación
          _buildSectionHeader('Aplicación'),
          ListTile(
            leading: const Icon(Icons.brightness_4),
            title: const Text('Tema Oscuro'),
            trailing: const Text('Activado'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión de la Aplicación'),
            trailing: const Text('1.0.0'),
          ),
          
          // Botón de cerrar sesión
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                authService.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('CERRAR SESIÓN'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  // Construir encabezado de sección
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // Construir elemento de estadísticas
  Widget _buildStatItem(String label, String value, IconData icon, {Color? valueColor}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: valueColor,
        ),
      ),
    );
  }
  
  // Obtener nombre legible de estrategia
  String _getStrategyName(TradeStrategy strategy) {
    switch (strategy) {
      case TradeStrategy.conservative:
        return 'Conservadora';
      case TradeStrategy.moderate:
        return 'Moderada';
      case TradeStrategy.aggressive:
        return 'Agresiva';
    }
  }
}