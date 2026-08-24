import 'package:flutter/material.dart';

class ContenedorGrafico extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget grafico;

  const ContenedorGrafico({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    required this.grafico,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            grafico,
          ],
        ),
      ),
    );
  }
}