# Quotex Signal App

Aplicación móvil para integrar gráficos de Quotex con señales de trading automatizadas.

## Características

- **WebView con gráficos en vivo de Quotex**: Visualiza gráficos reales de Quotex directamente en la aplicación.
- **Señales automáticas**: Recibe señales generadas por análisis técnico avanzado y machine learning.
- **Trading automatizado**: Ejecuta operaciones automáticas basadas en señales recibidas.
- **Diferentes estrategias**: Personaliza tu enfoque con estrategias conservadoras o agresivas.
- **Estadísticas detalladas**: Monitorea tu rendimiento con métricas en tiempo real.
- **Soporte para varios mercados**: OTC, FOREX y criptomonedas.

## Requisitos de instalación

- Flutter 3.7.0 o superior
- Dart 2.17.0 o superior
- Conexión a Internet para gráficos en tiempo real

## Instrucciones para Compilar

### Usando Codemagic

1. Clona este repositorio en tu cuenta de GitHub
2. Crea una cuenta en [Codemagic](https://codemagic.io/)
3. Agrega tu repositorio de GitHub a Codemagic
4. Usa la configuración del archivo `codemagic.yaml` incluido 
5. Inicia la compilación

### Compilación Local

```bash
# Instalar dependencias
flutter pub get

# Compilar versión de depuración
flutter build apk --debug

# Compilar versión de lanzamiento
flutter build apk --release
```

## Credenciales necesarias

Para la funcionalidad completa, necesitarás:
- Una cuenta en Quotex
- API Key de Zaffex (para señales premium)

## Desarrollo

La aplicación utiliza:
- WebView para visualizar gráficos de Quotex
- Provider para gestión de estado
- SharedPreferences para almacenamiento local
- HTTP para API calls

## Funcionalidades planeadas

- Notificaciones push para señales
- Integración con Telegram
- Análisis de gráficos mediante capturas de pantalla
- Soporte para más plataformas de opciones binarias

---

Desarrollado como parte del sistema de asistencia de trading Zaffex.