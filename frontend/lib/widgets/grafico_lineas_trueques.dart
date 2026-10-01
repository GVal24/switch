import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoLineasTrueques extends StatelessWidget {
  final List<String> meses;
  final List<dynamic> valores;

  const GraficoLineasTrueques({
    Key? key,
    required this.meses,
    required this.valores,
  }) : super(key: key);

  // Convierte los valores numéricos simples de la BD en puntos (X, Y) para fl_chart
  List<FlSpot> _generarPuntos() {
    List<FlSpot> puntos = [];
    for (int i = 0; i < valores.length; i++) {
      double valorY =
          (valores[i] is num) ? (valores[i] as num).toDouble() : 0.0;
      puntos.add(FlSpot(i.toDouble(), valorY));
    }
    return puntos.isNotEmpty ? puntos : const [FlSpot(0, 0)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPrincipal = theme.colorScheme.primary;

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < meses.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        meses[index],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 10,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade400, width: 1),
              left: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _generarPuntos(),
              isCurved: true,
              color: colorPrincipal,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: colorPrincipal,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: colorPrincipal.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
