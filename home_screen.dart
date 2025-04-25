import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/signal_service.dart';
import '../services/trading_service.dart';
import '../services/notifications_service.dart';
import 'login_screen.dart';
import 'chart_screen.dart';
import 'signals_screen.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // Lista de pantallas disponibles en la barra de navegación
  final List<Widget> _screens = [
    const ChartScreen(),
    const SignalsScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];
  
  // Títulos de las pantallas para mostrar en AppBar
  final List<String> _screenTitles = [
    'Gráficos de Trading',
    'Señales',
    'Análisis',
    'Ajustes',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar servicios
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ya no iniciamos auth aquí porque lo hicimos en main.dart
      await context.read<TradingService>().init();
      await context.read<SignalService>().fetchSignals();
      
      // Verificar y procesar nuevas señales para notificaciones
      final signalService = context.read<SignalService>();
      final notificationsService = context.read<NotificationsService>();
      
      if (signalService.signals.isNotEmpty) {
        await notificationsService.checkNewSignals(signalService.signals);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Verificar autenticación
    final authService = context.watch<AuthService>();
    final notificationsService = context.watch<NotificationsService>();
    
    // Si no está autenticado, mostrar pantalla de login
    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }
    
    // Si está autenticado, mostrar la pantalla principal
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_currentIndex]),
        actions: [
          // Botón de análisis de captura de gráfico
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => Navigator.pushNamed(context, '/chart_capture'),
            tooltip: 'Analizar gráfico',
          ),
          
          // Contador de notificaciones
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                tooltip: 'Notificaciones',
              ),
              if (notificationsService.notificationHistory.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationsService.notificationHistory.length.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, authService),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.candlestick_chart),
            label: 'Gráficos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.signal_cellular_alt),
            label: 'Señales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        selectedItemColor: Colors.blue,
        backgroundColor: const Color(0xFF1A1A1A),
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showGenerateSignalsDialog(),
              tooltip: 'Generar Señales',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  // Construir menú lateral
  Widget _buildDrawer(BuildContext context, AuthService authService) {
    final tradingService = context.watch<TradingService>();
    
    return Drawer(
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(authService.username ?? 'Usuario'),
              accountEmail: const Text('Cuenta de Quotex'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  (authService.username?.isNotEmpty == true)
                      ? authService.username![0].toUpperCase()
                      : 'Q',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue[800],
              ),
              otherAccountsPictures: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    '\$${tradingService.balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: tradingService.balance >= 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            // Elemento principal: Gráficos
            ListTile(
              leading: const Icon(Icons.candlestick_chart),
              title: const Text('Gráficos de Trading'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context); // Cerrar drawer
              },
            ),
            
            // Elemento principal: Señales
            ListTile(
              leading: const Icon(Icons.signal_cellular_alt),
              title: const Text('Señales'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            
            // Elemento: Análisis
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Análisis'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            
            // Elemento: Análisis de gráficos
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Analizar gráfico'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Nuevo',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chart_capture');
              },
            ),
            
            // Elemento: Notificaciones
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificaciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            
            const Divider(),
            
            // Sección: Trading
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'TRADING',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            
            // Trading automatizado
            SwitchListTile(
              title: const Text('Trading Automático'),
              value: tradingService.autoTrading,
              secondary: Icon(
                Icons.auto_awesome,
                color: tradingService.autoTrading ? Colors.blue : Colors.grey,
              ),
              onChanged: (bool value) {
                tradingService.setAutoTrading(value);
              },
            ),
            
            // Estrategia actual
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('Estrategia'),
              subtitle: Text(_getStrategyName(tradingService.currentStrategy)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showStrategyDialog(context, tradingService),
            ),
            
            const Divider(),
            
            // Ajustes y cerrar sesión
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              selected: _currentIndex == 3,
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmDialog(context, authService);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Diálogo para cambiar estrategia
  void _showStrategyDialog(BuildContext context, TradingService tradingService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Estrategia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStrategyOption(
                context,
                tradingService,
                TradeStrategy.conservative,
                'Conservadora',
                'Solo opera con señales de alta confianza',
                Icons.shield,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildStrategyOption(
                context,
                tradingService,
                TradeStrategy.moderate,
                'Moderada',
                'Balance entre riesgo y oportunidad',
                Icons.balance,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildStrategyOption(
                context,
                tradingService,
                TradeStrategy.aggressive,
                'Agresiva',
                'Mayor riesgo para mayor ganancia',
                Icons.bolt,
                Colors.orange,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
  
  // Opción individual de estrategia
  Widget _buildStrategyOption(
    BuildContext context,
    TradingService service,
    TradeStrategy strategy,
    String name,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = service.currentStrategy == strategy;
    
    return InkWell(
      onTap: () {
        service.setStrategy(strategy);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }
  
  // Diálogo para generar señales
  void _showGenerateSignalsDialog() {
    String selectedMarketType = 'OTC';
    int signalCount = 3;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Generar Señales'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de Mercado'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedMarketType,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'OTC', child: Text('OTC')),
                      DropdownMenuItem(value: 'FOREX', child: Text('FOREX')),
                      DropdownMenuItem(value: 'CRYPTO', child: Text('CRYPTO')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedMarketType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Cantidad de Señales'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: signalCount,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 1, child: Text('1 señal')),
                      DropdownMenuItem(value: 3, child: Text('3 señales')),
                      DropdownMenuItem(value: 5, child: Text('5 señales')),
                      DropdownMenuItem(value: 10, child: Text('10 señales')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        signalCount = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final signalService = context.read<SignalService>();
                    Navigator.pop(context);
                    
                    // Mostrar indicador de carga
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Generando señales...'),
                          ],
                        ),
                      ),
                    );
                    
                    // Generar señales
                    signalService.generateSignals(
                      marketType: selectedMarketType,
                      limit: signalCount,
                    ).then((_) {
                      Navigator.pop(context); // Cerrar diálogo de carga
                      
                      // Notificar al usuario
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$signalCount señales generadas con éxito'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }).catchError((error) {
                      Navigator.pop(context); // Cerrar diálogo de carga
                      
                      // Mostrar error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  },
                  child: const Text('Generar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Diálogo para confirmar cierre de sesión
  void _showLogoutConfirmDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                authService.logout();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
  
  // Obtener nombre de estrategia
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