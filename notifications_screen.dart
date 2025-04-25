import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notifications_service.dart';
import '../models/trading_alert.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Configuración'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSettingsTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlertDialog(),
        tooltip: 'Crear Alerta',
        child: const Icon(Icons.add_alert),
      ),
    );
  }
  
  // Tab 1: Configuración de alertas
  Widget _buildSettingsTab() {
    final notificationsService = Provider.of<NotificationsService>(context);
    final alerts = notificationsService.alerts;
    
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay alertas configuradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crea una alerta para recibir notificaciones',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Panel de configuración general
        _buildGeneralSettingsPanel(notificationsService),
        
        // Lista de alertas
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              return _buildAlertItem(alerts[index], notificationsService);
            },
          ),
        ),
      ],
    );
  }
  
  // Tab 2: Historial de notificaciones
  Widget _buildHistoryTab() {
    final notificationsService = Provider.of<NotificationsService>(context);
    final notifications = notificationsService.notificationHistory;
    
    if (notifications.isEmpty) {
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
              'No hay notificaciones recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }
  
  // Panel de configuración general
  Widget _buildGeneralSettingsPanel(NotificationsService service) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración general',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Opción para activar/desactivar todas las notificaciones
            SwitchListTile(
              title: const Text('Notificaciones'),
              subtitle: const Text('Activar todas las notificaciones'),
              value: service.notificationsEnabled,
              onChanged: (value) => service.setNotificationsEnabled(value),
              secondary: const Icon(Icons.notifications),
            ),
            
            // Opción para sonido
            SwitchListTile(
              title: const Text('Sonido'),
              subtitle: const Text('Reproducir sonido con las notificaciones'),
              value: service.soundEnabled,
              onChanged: (value) => service.setSoundEnabled(value),
              secondary: const Icon(Icons.volume_up),
              enabled: service.notificationsEnabled,
            ),
            
            // Opción para vibración
            SwitchListTile(
              title: const Text('Vibración'),
              subtitle: const Text('Vibrar al recibir notificaciones'),
              value: service.vibrationEnabled,
              onChanged: (value) => service.setVibrationEnabled(value),
              secondary: const Icon(Icons.vibration),
              enabled: service.notificationsEnabled,
            ),
            
            const Divider(),
            
            // Alertas automáticas para señales
            SwitchListTile(
              title: const Text('Alertas de Señales'),
              subtitle: const Text('Notificar automáticamente nuevas señales'),
              value: service.signalAlertsEnabled,
              onChanged: (value) => service.setSignalAlertsEnabled(value),
              secondary: const Icon(Icons.auto_graph),
              enabled: service.notificationsEnabled,
            ),
          ],
        ),
      ),
    );
  }
  
  // Elemento de alerta individual
  Widget _buildAlertItem(TradingAlert alert, NotificationsService service) {
    IconData typeIcon;
    Color typeColor;
    
    // Determinar icono y color según tipo de alerta
    switch (alert.type) {
      case AlertType.price:
        typeIcon = Icons.trending_up;
        typeColor = Colors.blue;
        break;
      case AlertType.signal:
        typeIcon = Icons.signal_cellular_alt;
        typeColor = Colors.green;
        break;
      case AlertType.news:
        typeIcon = Icons.newspaper;
        typeColor = Colors.orange;
        break;
      default:
        typeIcon = Icons.notifications;
        typeColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Icono del tipo de alerta
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Detalles de la alerta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        alert.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Switch para activar/desactivar
                Switch(
                  value: alert.enabled,
                  onChanged: (value) => service.toggleAlert(alert.id, value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Condiciones
            Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(
                      _getConditionText(alert),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditAlertDialog(alert),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _showDeleteAlertDialog(alert),
                  color: Colors.red,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Elemento de notificación en historial
  Widget _buildNotificationItem(NotificationItem notification) {
    IconData typeIcon;
    Color typeColor;
    
    // Determinar icono y color según tipo de notificación
    switch (notification.type) {
      case 'price':
        typeIcon = Icons.trending_up;
        typeColor = Colors.blue;
        break;
      case 'signal':
        typeIcon = Icons.signal_cellular_alt;
        typeColor = Colors.green;
        break;
      case 'news':
        typeIcon = Icons.newspaper;
        typeColor = Colors.orange;
        break;
      default:
        typeIcon = Icons.notifications;
        typeColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            typeIcon,
            color: typeColor,
          ),
        ),
        title: Text(notification.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(notification.timestamp),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showNotificationDetailsDialog(notification),
      ),
    );
  }
  
  // Convertir condición a texto legible
  String _getConditionText(TradingAlert alert) {
    switch (alert.type) {
      case AlertType.price:
        String direction = alert.condition['direction'] == 'above' ? 'sube por encima de' : 'baja por debajo de';
        return '${alert.condition['asset']} $direction ${alert.condition['value']}';
      case AlertType.signal:
        return 'Señal con confianza ${alert.condition['confidence']} o superior';
      case AlertType.news:
        return 'Noticias importantes para ${alert.condition['asset']}';
      default:
        return '';
    }
  }
  
  // Formatear fecha y hora
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  // Diálogos para gestión de alertas
  
  // Diálogo para crear nueva alerta
  void _showCreateAlertDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    AlertType selectedType = AlertType.price;
    Map<String, dynamic> condition = {
      'asset': 'EUR/USD',
      'direction': 'above',
      'value': '1.05',
    };
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear Nueva Alerta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ej: Alerta de precio EUR/USD',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Ej: Alertarme cuando el precio supere...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de alerta
                    const Text(
                      'Tipo de Alerta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<AlertType>(
                      value: selectedType,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: AlertType.price,
                          child: Row(
                            children: const [
                              Icon(Icons.trending_up, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Precio'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: AlertType.signal,
                          child: Row(
                            children: const [
                              Icon(Icons.signal_cellular_alt, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Señal'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: AlertType.news,
                          child: Row(
                            children: const [
                              Icon(Icons.newspaper, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Noticia'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                          
                          // Actualizar condición según tipo
                          switch (selectedType) {
                            case AlertType.price:
                              condition = {
                                'asset': 'EUR/USD',
                                'direction': 'above',
                                'value': '1.05',
                              };
                              break;
                            case AlertType.signal:
                              condition = {
                                'confidence': 'ALTA',
                                'market_type': 'OTC',
                              };
                              break;
                            case AlertType.news:
                              condition = {
                                'asset': 'EUR/USD',
                                'importance': 'high',
                              };
                              break;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Condiciones específicas según el tipo
                    const Text(
                      'Condiciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Campos específicos según tipo de alerta
                    if (selectedType == AlertType.price) ...[
                      // Par de activos
                      DropdownButton<String>(
                        value: condition['asset'],
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'EUR/USD', child: Text('EUR/USD')),
                          DropdownMenuItem(value: 'GBP/USD', child: Text('GBP/USD')),
                          DropdownMenuItem(value: 'USD/JPY', child: Text('USD/JPY')),
                          DropdownMenuItem(value: 'OTC_EUR/USD', child: Text('OTC EUR/USD')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            condition['asset'] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Dirección (por encima/por debajo)
                      Row(
                        children: [
                          Radio<String>(
                            value: 'above',
                            groupValue: condition['direction'],
                            onChanged: (value) {
                              setState(() {
                                condition['direction'] = value;
                              });
                            },
                          ),
                          const Text('Por encima de'),
                          Radio<String>(
                            value: 'below',
                            groupValue: condition['direction'],
                            onChanged: (value) {
                              setState(() {
                                condition['direction'] = value;
                              });
                            },
                          ),
                          const Text('Por debajo de'),
                        ],
                      ),
                      
                      // Valor de precio
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                          hintText: 'Ej: 1.05',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          condition['value'] = value;
                        },
                        initialValue: condition['value'],
                      ),
                    ],
                    
                    if (selectedType == AlertType.signal) ...[
                      // Nivel de confianza
                      DropdownButton<String>(
                        value: condition['confidence'],
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                          DropdownMenuItem(value: 'MEDIA', child: Text('Media')),
                          DropdownMenuItem(value: 'BAJA', child: Text('Baja')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            condition['confidence'] = value;
                          });
                        },
                      ),
                      
                      // Tipo de mercado
                      DropdownButton<String>(
                        value: condition['market_type'],
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'OTC', child: Text('OTC')),
                          DropdownMenuItem(value: 'FOREX', child: Text('FOREX')),
                          DropdownMenuItem(value: 'CRYPTO', child: Text('CRYPTO')),
                          DropdownMenuItem(value: 'ANY', child: Text('Cualquiera')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            condition['market_type'] = value;
                          });
                        },
                      ),
                    ],
                    
                    if (selectedType == AlertType.news) ...[
                      // Par para noticias
                      DropdownButton<String>(
                        value: condition['asset'],
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'EUR/USD', child: Text('EUR/USD')),
                          DropdownMenuItem(value: 'GBP/USD', child: Text('GBP/USD')),
                          DropdownMenuItem(value: 'USD/JPY', child: Text('USD/JPY')),
                          DropdownMenuItem(value: 'ANY', child: Text('Cualquiera')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            condition['asset'] = value;
                          });
                        },
                      ),
                      
                      // Importancia
                      DropdownButton<String>(
                        value: condition['importance'],
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'high', child: Text('Alta')),
                          DropdownMenuItem(value: 'medium', child: Text('Media')),
                          DropdownMenuItem(value: 'low', child: Text('Baja')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            condition['importance'] = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, introduce un título')),
                      );
                      return;
                    }
                    
                    // Crear alerta
                    final newAlert = TradingAlert(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      description: descriptionController.text,
                      type: selectedType,
                      condition: condition,
                      enabled: true,
                      createdAt: DateTime.now(),
                    );
                    
                    // Añadir alerta
                    Provider.of<NotificationsService>(context, listen: false)
                        .addAlert(newAlert);
                    
                    Navigator.pop(context);
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Diálogo para editar alerta existente
  void _showEditAlertDialog(TradingAlert alert) {
    final TextEditingController titleController = TextEditingController(text: alert.title);
    final TextEditingController descriptionController = TextEditingController(text: alert.description);
    
    AlertType selectedType = alert.type;
    Map<String, dynamic> condition = Map.from(alert.condition);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Alerta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Condiciones específicas según el tipo
                    const Text(
                      'Condiciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Campos específicos según tipo de alerta (similar a crear)
                    if (selectedType == AlertType.price) ...[
                      // Par de activos
                      DropdownButton<String>(
                        value: condition['asset'],
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'EUR/USD', child: Text('EUR/USD')),
                          DropdownMenuItem(value: 'GBP/USD', child: Text('GBP/USD')),
                          DropdownMenuItem(value: 'USD/JPY', child: Text('USD/JPY')),
                          DropdownMenuItem(value: 'OTC_EUR/USD', child: Text('OTC EUR/USD')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            condition['asset'] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Dirección (por encima/por debajo)
                      Row(
                        children: [
                          Radio<String>(
                            value: 'above',
                            groupValue: condition['direction'],
                            onChanged: (value) {
                              setState(() {
                                condition['direction'] = value;
                              });
                            },
                          ),
                          const Text('Por encima de'),
                          Radio<String>(
                            value: 'below',
                            groupValue: condition['direction'],
                            onChanged: (value) {
                              setState(() {
                                condition['direction'] = value;
                              });
                            },
                          ),
                          const Text('Por debajo de'),
                        ],
                      ),
                      
                      // Valor de precio
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          condition['value'] = value;
                        },
                        controller: TextEditingController(text: condition['value']),
                      ),
                    ],
                    
                    // Para los otros tipos sería similar
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, introduce un título')),
                      );
                      return;
                    }
                    
                    // Actualizar alerta
                    final updatedAlert = TradingAlert(
                      id: alert.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      type: selectedType,
                      condition: condition,
                      enabled: alert.enabled,
                      createdAt: alert.createdAt,
                    );
                    
                    // Actualizar en el servicio
                    Provider.of<NotificationsService>(context, listen: false)
                        .updateAlert(updatedAlert);
                    
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Diálogo para confirmar eliminación
  void _showDeleteAlertDialog(TradingAlert alert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Alerta'),
          content: Text('¿Estás seguro de que deseas eliminar la alerta "${alert.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Eliminar alerta
                Provider.of<NotificationsService>(context, listen: false)
                    .removeAlert(alert.id);
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
  
  // Diálogo para mostrar detalles de notificación
  void _showNotificationDetailsDialog(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(notification.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              Text(
                'Recibida: ${_formatDateTime(notification.timestamp)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              if (notification.data != null && notification.data!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Datos adicionales:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(notification.data.toString()),
                ),
              ],
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
}