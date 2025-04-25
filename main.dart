import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Servicios
import 'services/auth_service.dart';
import 'services/signal_service.dart';
import 'services/trading_service.dart';
import 'services/notifications_service.dart';

// Pantallas
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/signals_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/chart_capture_screen.dart';

// Para notificaciones del sistema
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Inicializar notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: null,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Aquí podemos manejar la respuesta a la notificación
      print('Notificación: ${response.payload}');
    },
  );
  
  // Inicializar Firebase (para analytics y notificaciones push)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Fallar de forma silenciosa si Firebase no está configurado
    print('Error al inicializar Firebase: $e');
  }
  
  // Ejecutar la aplicación
  runApp(const QuotexApp());
}

class QuotexApp extends StatelessWidget {
  const QuotexApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Proveedores de servicios principales
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SignalService()),
        ChangeNotifierProvider(create: (_) => TradingService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          // Inicializar servicios
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await context.read<AuthService>().init();
            await context.read<NotificationsService>().init();
          });
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Quotex Signals App',
            theme: ThemeData(
              // Tema oscuro para la aplicación (similar a Quotex)
              brightness: Brightness.dark,
              primaryColor: Colors.blue,
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1A1A1A),
                elevation: 0,
              ),
              cardTheme: CardTheme(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textTheme: const TextTheme(
                bodyText1: TextStyle(color: Colors.white),
                bodyText2: TextStyle(color: Colors.white),
              ),
              // Personalización de colores y tamaños
              colorScheme: ColorScheme.dark(
                primary: Colors.blue,
                secondary: Colors.blue[700]!,
                surface: const Color(0xFF1A1A1A),
                background: const Color(0xFF121212),
                error: Colors.red,
              ),
              // Estilos de botones y controles
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Estilos de campos de texto
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            // Pantalla de inicio (dependiendo de autenticación)
            home: authService.isLoading
                ? const SplashScreen()
                : authService.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen(),
            
            // Rutas para navegación
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/chart': (context) => const ChartScreen(),
              '/signals': (context) => const SignalsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/chart_capture': (context) => const ChartCaptureScreen(),
            },
          );
        },
      ),
    );
  }
}

// Pantalla de carga mientras se inicializa la aplicación
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la aplicación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.candlestick_chart,
                size: 64,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quotex Signals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cargando...',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}