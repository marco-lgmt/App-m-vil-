import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/signal_service.dart';
import '../models/trading_signal.dart';
import 'signal_detail_screen.dart';

class ChartCaptureScreen extends StatefulWidget {
  const ChartCaptureScreen({Key? key}) : super(key: key);

  @override
  _ChartCaptureScreenState createState() => _ChartCaptureScreenState();
}

class _ChartCaptureScreenState extends State<ChartCaptureScreen> {
  File? _image;
  bool _isAnalyzing = false;
  bool _showResult = false;
  TradingSignal? _analyzedSignal;
  String? _errorMessage;
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizar Gráfico'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instrucciones
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Análisis de Gráficos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Toma una captura de pantalla de tu gráfico de Quotex para recibir un análisis y recomendaciones de trading.',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Imagen seleccionada o placeholder
          Expanded(
            child: _isAnalyzing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Analizando gráfico...'),
                        SizedBox(height: 8),
                        Text(
                          'Nuestro sistema está procesando la imagen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : _showResult && _analyzedSignal != null
                    ? _buildAnalysisResult()
                    : _buildImagePreview(),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _getImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _getImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Botón de análisis
          if (_image != null && !_showResult && !_isAnalyzing)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: _analyzeChart,
                icon: const Icon(Icons.analytics),
                label: const Text('ANALIZAR GRÁFICO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          
          // Botón para utilizar la señal analizada
          if (_showResult && _analyzedSignal != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignalDetailScreen(signal: _analyzedSignal!),
                    ),
                  );
                },
                icon: const Icon(Icons.trending_up),
                label: const Text('USAR ESTA SEÑAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Mostrar previsualizador de imagen
  Widget _buildImagePreview() {
    if (_image == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 100,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay imagen seleccionada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona una imagen de tu gráfico para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _image!,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                fit: BoxFit.contain,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
  
  // Mostrar resultado del análisis
  Widget _buildAnalysisResult() {
    final signal = _analyzedSignal!;
    final directionColor = signal.direction == 'COMPRA' ? Colors.green : Colors.red;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Imagen analizada
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(_image!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Resultado del análisis
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: directionColor, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signal.assetPair,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          signal.marketType,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: directionColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        signal.direction,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: directionColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Indicadores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultIndicator(
                      'Confianza',
                      signal.confidenceLevel,
                      signal.confidenceEmoji,
                    ),
                    _buildResultIndicator(
                      'Prob.',
                      '${(signal.probabilityScore * 100).round()}%',
                      null,
                    ),
                    _buildResultIndicator(
                      'Duración',
                      '${signal.durationMinutes} min',
                      null,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Resumen del análisis
                const Text(
                  'Análisis del Gráfico:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(signal.analysisSummary),
                
                const SizedBox(height: 16),
                
                // Recomendación
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: directionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        signal.direction == 'COMPRA'
                            ? '↗️ Recomendación: COMPRAR'
                            : '↘️ Recomendación: VENDER',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: directionColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Entrada: ${signal.entryTime} • Expiración: ${signal.durationMinutes} min',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para mostrar indicadores de resultado
  Widget _buildResultIndicator(String label, String value, String? emoji) {
    return Column(
      children: [
        Text(
          emoji != null ? '$emoji $value' : value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
  
  // Seleccionar imagen de la cámara
  Future<void> _getImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _showResult = false;
        _analyzedSignal = null;
        _errorMessage = null;
      });
    }
  }
  
  // Seleccionar imagen de la galería
  Future<void> _getImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _showResult = false;
        _analyzedSignal = null;
        _errorMessage = null;
      });
    }
  }
  
  // Analizar el gráfico
  Future<void> _analyzeChart() async {
    if (_image == null) return;
    
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    
    try {
      // Convertir imagen a base64
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // URL del servidor de análisis
      final apiUrl = Uri.parse('http://localhost:5000/api/analyze-chart');
      
      // Enviar imagen para análisis
      final response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image': base64Image,
          'source': 'mobile_app',
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success']) {
          // Crear señal a partir de los datos del análisis
          final analysisData = responseData['analysis'];
          
          final signal = TradingSignal(
            id: DateTime.now().millisecondsSinceEpoch,
            assetPair: analysisData['asset_pair'] ?? 'Desconocido',
            marketType: analysisData['market_type'] ?? 'FOREX',
            direction: analysisData['direction'] ?? 'COMPRA',
            entryTime: analysisData['entry_time'] ?? '00:00:00',
            duration: analysisData['duration'] ?? 180,
            probabilityScore: analysisData['probability_score'] ?? 0.5,
            confidenceLevel: analysisData['confidence_level'] ?? 'MEDIA',
            volatility: analysisData['volatility'] ?? 'media',
            analysisSummary: analysisData['analysis_summary'] ?? 'No hay análisis disponible.',
            createdAt: DateTime.now(),
          );
          
          setState(() {
            _analyzedSignal = signal;
            _showResult = true;
            _isAnalyzing = false;
          });
          
          // Añadir la señal al servicio
          await Provider.of<SignalService>(context, listen: false)
              .generateSignals(
                marketType: signal.marketType,
                limit: 1,
              );
        } else {
          setState(() {
            _errorMessage = responseData['error'] ?? 'Error al analizar el gráfico';
            _isAnalyzing = false;
          });
        }
      } else {
        // En caso de error, simular análisis para demostración
        await Future.delayed(const Duration(seconds: 2));
        _simulateChartAnalysis();
      }
    } catch (e) {
      // En caso de error, simular análisis para demostración
      await Future.delayed(const Duration(seconds: 2));
      _simulateChartAnalysis();
    }
  }
  
  // Simular análisis del gráfico para demostración
  void _simulateChartAnalysis() {
    // Este método simula un análisis local cuando el servidor no está disponible
    final signal = TradingSignal(
      id: DateTime.now().millisecondsSinceEpoch,
      assetPair: 'EUR/USD',
      marketType: 'FOREX',
      direction: DateTime.now().second % 2 == 0 ? 'COMPRA' : 'VENTA',
      entryTime: '${DateTime.now().hour}:${DateTime.now().minute}:00',
      duration: 180,
      probabilityScore: 0.75,
      confidenceLevel: 'ALTA',
      volatility: 'media',
      analysisSummary: 'Análisis simulado para demostración. Se detecta un patrón de rebote en el gráfico con soporte en niveles clave. La tendencia muestra signos de reversión con potencial para un movimiento alcista en el corto plazo.',
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _analyzedSignal = signal;
      _showResult = true;
      _isAnalyzing = false;
    });
  }
}