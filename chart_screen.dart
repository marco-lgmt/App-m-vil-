import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/trading_service.dart';
import '../services/signal_service.dart';
import '../models/trading_signal.dart';
import '../widgets/signal_indicator.dart';
import '../widgets/trade_controls.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  WebViewController? _webViewController;
  String _currentAsset = 'EUR/USD';
  String _timeframe = '1m';
  bool _chartLoaded = false;
  bool _showOverlay = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  // Método para cargar el gráfico de Quotex en el WebView
  void _loadQuotexChart() {
    if (_webViewController != null) {
      _webViewController!.loadUrl(
        'https://quotex.com/en/trade/$_currentAsset?tf=$_timeframe',
        headers: {'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'},
      );
    }
  }
  
  // Método para cambiar de par de divisas
  void _changeAssetPair(String newAsset) {
    setState(() {
      _currentAsset = newAsset;
      _chartLoaded = false;
    });
    _loadQuotexChart();
  }
  
  // Método para cambiar el timeframe
  void _changeTimeframe(String newTimeframe) {
    setState(() {
      _timeframe = newTimeframe;
      _chartLoaded = false;
    });
    _loadQuotexChart();
  }
  
  // Método para mostrar/ocultar controles de overlay
  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }
  
  // Método para ejecutar una operación basada en la señal actual
  void _executeTrade(String direction, double amount) {
    final tradingService = context.read<TradingService>();
    final signalService = context.read<SignalService>();
    
    // Obtener señal actual (por simplicidad, usamos la primera)
    if (signalService.signals.isNotEmpty) {
      final signal = signalService.signals.first;
      tradingService.executeTrade(signal);
      
      // Mostrar notificación de operación ejecutada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operación de $direction ejecutada por \$${amount.toStringAsFixed(2)}'),
          backgroundColor: direction == 'COMPRA' ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  // Construir la barra de selección de pares
  Widget _buildAssetSelector() {
    final pairs = [
      'EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD',
      'OTC_EUR/USD', 'OTC_GBP/USD', 'OTC_USD/JPY', 'OTC_AUD/USD',
    ];
    
    return Container(
      height: 40,
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pairs.length,
        itemBuilder: (context, index) {
          final pair = pairs[index];
          final isSelected = pair == _currentAsset;
          
          return InkWell(
            onTap: () => _changeAssetPair(pair),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                pair,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Construir la barra de timeframes
  Widget _buildTimeframeSelector() {
    final timeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1d'];
    
    return Container(
      height: 40,
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeframes.length,
        itemBuilder: (context, index) {
          final tf = timeframes[index];
          final isSelected = tf == _timeframe;
          
          return InkWell(
            onTap: () => _changeTimeframe(tf),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tf,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Obtener servicios
    final signalService = context.watch<SignalService>();
    final tradingService = context.watch<TradingService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotex Gráficos', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_showOverlay ? Icons.layers_clear : Icons.layers),
            onPressed: _toggleOverlay,
            tooltip: _showOverlay ? 'Ocultar señales' : 'Mostrar señales',
          ),
        ],
      ),
      body: Column(
        children: [
          // Selectores de par y timeframe
          _buildAssetSelector(),
          _buildTimeframeSelector(),
          
          // WebView principal para mostrar el gráfico de Quotex
          Expanded(
            child: Stack(
              children: [
                // WebView con el gráfico de Quotex
                WebView(
                  initialUrl: 'https://quotex.com/en/trade/$_currentAsset?tf=$_timeframe',
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onPageStarted: (url) {
                    setState(() {
                      _chartLoaded = false;
                    });
                  },
                  onPageFinished: (url) {
                    setState(() {
                      _chartLoaded = true;
                    });
                    
                    // Inyectar JavaScript para personalizar la visualización si es necesario
                    // (eliminar elementos innecesarios de la interfaz de Quotex, etc.)
                    _webViewController?.evaluateJavascript('''
                      // Ocultar elementos de la interfaz que no necesitamos
                      document.querySelectorAll('.header, .footer, .sidebar').forEach(el => {
                        if (el) el.style.display = 'none';
                      });
                      
                      // Ampliar el gráfico para que ocupe toda la pantalla
                      const chartElement = document.querySelector('.chart-container');
                      if (chartElement) {
                        chartElement.style.width = '100%';
                        chartElement.style.height = '100%';
                      }
                    ''');
                  },
                  gestureNavigationEnabled: false,
                ),
                
                // Indicador de carga
                if (!_chartLoaded)
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                
                // Overlay con señales y controles
                if (_showOverlay && _chartLoaded && signalService.signals.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    left: 16,
                    child: SignalIndicator(signal: signalService.signals.first),
                  ),
              ],
            ),
          ),
          
          // Controles de trading
          TradeControls(
            autoTrading: tradingService.autoTrading,
            tradeAmount: tradingService.tradeAmount,
            onAutoTradingChanged: (value) => tradingService.setAutoTrading(value),
            onAmountChanged: (value) => tradingService.setTradeAmount(value),
            onBuyPressed: () => _executeTrade('COMPRA', tradingService.tradeAmount),
            onSellPressed: () => _executeTrade('VENTA', tradingService.tradeAmount),
          ),
        ],
      ),
    );
  }
}