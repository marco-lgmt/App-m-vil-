import 'package:flutter/material.dart';

class TradeControls extends StatelessWidget {
  final bool autoTrading;
  final double tradeAmount;
  final Function(bool) onAutoTradingChanged;
  final Function(double) onAmountChanged;
  final VoidCallback onBuyPressed;
  final VoidCallback onSellPressed;
  
  const TradeControls({
    Key? key,
    required this.autoTrading,
    required this.tradeAmount,
    required this.onAutoTradingChanged,
    required this.onAmountChanged,
    required this.onBuyPressed,
    required this.onSellPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Color(0xFF333333),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Fila principal con controles
          Row(
            children: [
              // Switch de auto trading
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Text('AUTO:', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: autoTrading,
                      onChanged: onAutoTradingChanged,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              
              // Selector de monto
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<double>(
                    value: tradeAmount,
                    isExpanded: true,
                    isDense: true,
                    underline: Container(),
                    dropdownColor: Colors.grey[800],
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: [5.0, 10.0, 20.0, 50.0, 100.0].map((amount) {
                      return DropdownMenuItem<double>(
                        value: amount,
                        child: Text(
                          '\$${amount.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onAmountChanged(value);
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Botón de compra
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onBuyPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('COMPRA'),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Botón de venta
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onSellPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('VENTA'),
                ),
              ),
            ],
          ),
          
          // Nota informativa (opcional para modo auto)
          if (autoTrading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo automático activado. Las operaciones se ejecutarán automáticamente según las señales recibidas.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}