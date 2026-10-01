import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficoTortaEsfuerzo extends StatelessWidget {
  final Map<String, dynamic> esfuerzoDistribucion;

  const GraficoTortaEsfuerzo({Key? key, required this.esfuerzoDistribucion})
      : super(key: key);

  /// Helper para parsear cualquier tipo (int, double, String, null) a double de forma 100% segura
  double _toDoubleSeguro(dynamic valor) {
    if (valor == null) return 0.0;
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final double simple = _toDoubleSeguro(esfuerzoDistribucion['Simple']);
    final double medio = _toDoubleSeguro(esfuerzoDistribucion['Medio']);
    final double alto = _toDoubleSeguro(esfuerzoDistribucion['Alto']);

    final bool todosCero = (simple == 0 && medio == 0 && alto == 0);

    if (todosCero) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Sin datos de esfuerzo registrados',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 35,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: simple > 0 ? simple : 0.001,
                  title: '${simple.toStringAsFixed(0)}%',
                  radius: 45,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: medio > 0 ? medio : 0.001,
                  title: '${medio.toStringAsFixed(0)}%',
                  radius: 45,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.redAccent,
                  value: alto > 0 ? alto : 0.001,
                  title: '${alto.toStringAsFixed(0)}%',
                  radius: 45,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Leyendas inferiores para identificar los colores
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _IndicadorLeyenda(color: Colors.green, texto: 'Simple ($simple%)'),
            _IndicadorLeyenda(color: Colors.orange, texto: 'Medio ($medio%)'),
            _IndicadorLeyenda(color: Colors.redAccent, texto: 'Alto ($alto%)'),
          ],
        ),
      ],
    );
  }
}

class _IndicadorLeyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _IndicadorLeyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(texto,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
