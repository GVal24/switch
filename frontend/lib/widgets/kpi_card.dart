import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const KpiCard({
    Key? key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 8),
            Text(valor,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(titulo,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
