import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onCerrarSesion;
  final bool modoAccesibleActivo;

  const AdminDashboardScreen({
    Key? key,
    required this.onCerrarSesion,
    this.modoAccesibleActivo = false,
  }) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _cargando = true;
  Map<String, dynamic> _metricas = {};
  List<dynamic> _reportes = [];
  List<dynamic> _sugerenciasEsfuerzo = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    final resultados = await Future.wait([
      AdminService.obtenerEstadisticasAdmin(),
      AdminService.obtenerReportesAdmin(),
      AdminService.obtenerSugerenciasEsfuerzo(),
    ]);

    if (!mounted) return;
    setState(() {
      _metricas = resultados[0] as Map<String, dynamic>;
      _reportes = resultados[1] as List<dynamic>;
      _sugerenciasEsfuerzo = resultados[2] as List<dynamic>;
      _cargando = false;
    });
  }

  String _metrica(String clave, {String fallback = '0'}) {
    final valor = _metricas[clave];
    return valor == null ? fallback : valor.toString();
  }

  void _mostrarNotificacion(String mensaje, Color colorFondo) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TextStyle(fontSize: widget.modoAccesibleActivo ? 16 : 14),
        ),
        backgroundColor: colorFondo,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _suspenderUsuario(Map<String, dynamic> rep) async {
    final dias = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficieTarjeta,
        title: Text(
          'Suspender a ${rep['reportado_nombre'] ?? 'usuario'}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          'Elegí cuántos días no podrá ingresar a Switch. Vencido el plazo, la suspensión se levanta sola.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ...[7, 15, 30].map(
            (d) => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.acentoNaranja),
              onPressed: () => Navigator.pop(ctx, d),
              child: Text('${d}d', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );

    if (dias == null) return;

    final res = await AdminService.suspenderUsuario(
      (rep['reportado_id'] ?? '').toString(),
      dias,
      reporteId: (rep['id'] ?? '').toString(),
    );

    if (!mounted) return;
    _mostrarNotificacion(
      res['mensaje'] ?? (res['exito'] == true ? 'Usuario suspendido.' : 'No se pudo suspender al usuario.'),
      res['exito'] == true ? AppTheme.acentoNaranja : Colors.redAccent,
    );
    if (res['exito'] == true) _cargarDatos();
  }

  Future<void> _darDeBajaUsuario(Map<String, dynamic> rep) async {
    final exito = await AdminService.darDeBajaUsuario(
      (rep['reportado_id'] ?? '').toString(),
      (rep['id'] ?? '').toString(),
    );

    if (!mounted) return;
    if (exito) {
      _mostrarNotificacion(
        'Usuario "${rep['reportado_nombre']}" ha sido bloqueado permanentemente.',
        Colors.redAccent,
      );
      _cargarDatos();
    } else {
      _mostrarNotificacion('No se pudo bloquear al usuario.', Colors.redAccent);
    }
  }

  Future<void> _desestimarReporte(Map<String, dynamic> rep) async {
    final exito = await AdminService.desestimarReporte((rep['id'] ?? '').toString());

    if (!mounted) return;
    if (exito) {
      _mostrarNotificacion('Reporte desestimado.', Colors.grey.shade700);
      _cargarDatos();
    } else {
      _mostrarNotificacion('No se pudo desestimar el reporte.', Colors.redAccent);
    }
  }

  Future<void> _aplicarSugerencia(Map<String, dynamic> sug) async {
    final res = await AdminService.aplicarSugerenciaEsfuerzo((sug['id'] ?? '').toString());
    if (!mounted) return;
    _mostrarNotificacion(
      res['mensaje'] ?? (res['exito'] == true ? 'Nivel actualizado.' : 'No se pudo aplicar.'),
      res['exito'] == true ? AppTheme.acentoVerdeEco : Colors.redAccent,
    );
    if (res['exito'] == true) _cargarDatos();
  }

  Future<void> _descartarSugerencia(Map<String, dynamic> sug) async {
    final exito = await AdminService.descartarSugerenciaEsfuerzo((sug['id'] ?? '').toString());
    if (!mounted) return;
    _mostrarNotificacion(
      exito ? 'Sugerencia descartada.' : 'No se pudo descartar.',
      exito ? Colors.grey.shade700 : Colors.redAccent,
    );
    if (exito) _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final bool esAccesible = widget.modoAccesibleActivo;
    final List<String> meses = (_metricas['meses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final List<dynamic> actividad = _metricas['actividadMensual'] as List<dynamic>? ?? [];
    final double maxActividad = actividad.isEmpty
        ? 1
        : actividad.map((v) => (v is num ? v.toDouble() : 0.0)).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Panel de Administración',
          style: TextStyle(fontSize: esAccesible ? 22 : 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: esAccesible ? 28 : 24),
            tooltip: 'Actualizar datos',
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: Icon(Icons.logout, size: esAccesible ? 28 : 24),
            tooltip: 'Cerrar sesión Admin',
            onPressed: widget.onCerrarSesion,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppTheme.acentoVerdeEco))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: AppTheme.acentoVerdeEco,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= SECCIÓN 1: MÉTRICAS Y GRÁFICOS =================
                    Text(
                      '📊 Métricas de la Red',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: esAccesible ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Resumen en vivo de la comunidad · Efectividad de trueques: ${_metrica('tasaEfectividad', fallback: '-')} ',
                      style: TextStyle(color: AppTheme.textoSecundario, fontSize: esAccesible ? 15 : 13),
                    ),
                    const SizedBox(height: 14),

                    // Tarjetas KPI resumen
                    Row(
                      children: [
                        _buildTarjetaKpi(
                          'Usuarios',
                          _metrica('usuariosActivos'),
                          Icons.people_alt_outlined,
                          AppTheme.acentoVerdeEco,
                          esAccesible,
                        ),
                        const SizedBox(width: 10),
                        _buildTarjetaKpi(
                          'Trueques',
                          _metrica('truequesMes'),
                          Icons.swap_horizontal_circle_outlined,
                          AppTheme.acentoAzulTurquesa,
                          esAccesible,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTarjetaKpi(
                          'Asistencias QR',
                          _metrica('voluntariadosQr'),
                          Icons.qr_code_scanner_rounded,
                          Colors.amber,
                          esAccesible,
                        ),
                        const SizedBox(width: 10),
                        _buildTarjetaKpi(
                          'Denuncias',
                          _metrica('reportesPendientes'),
                          Icons.warning_amber_rounded,
                          Colors.redAccent,
                          esAccesible,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gráfico de Barras (Actividad mensual real)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.superficieTarjeta,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '📈 Actividad de Trueques (Mensual)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: esAccesible ? 16 : 14,
                                  ),
                                ),
                              ),
                              Icon(Icons.bar_chart, color: AppTheme.acentoVerdeEco, size: esAccesible ? 28 : 24),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (meses.isEmpty || actividad.isEmpty)
                            Text(
                              'Sin datos de actividad todavía.',
                              style: TextStyle(color: AppTheme.textoSecundario, fontSize: esAccesible ? 14 : 12),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(meses.length, (i) {
                                final valor = i < actividad.length && actividad[i] is num
                                    ? (actividad[i] as num).toDouble()
                                    : 0.0;
                                final proporcion = maxActividad == 0 ? 0.15 : (valor / maxActividad).clamp(0.15, 1.0);
                                return Expanded(
                                  child: _buildBarraGrafico(meses[i], proporcion, esAccesible),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    // ================= SECCIÓN 2: DENUNCIAS Y REPORTES =================
                    Text(
                      '🚨 Denuncias y Reportes Pendientes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: esAccesible ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revisá los reclamos de la comunidad y sancioná usuarios.',
                      style: TextStyle(color: AppTheme.textoSecundario, fontSize: esAccesible ? 15 : 13),
                    ),
                    const SizedBox(height: 16),

                    _reportes.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppTheme.superficieTarjeta,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '¡No hay denuncias pendientes! 🎉',
                                style: TextStyle(color: AppTheme.textoSecundario, fontSize: esAccesible ? 18 : 16),
                              ),
                            ),
                          )
                        : Column(
                            children: _reportes.map<Widget>((rep) {
                              final estado = (rep['estado'] ?? '').toString();
                              final esPendiente = estado == 'PENDIENTE';

                              return Card(
                                color: AppTheme.superficieTarjeta,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: esPendiente ? Colors.redAccent.withValues(alpha: 0.4) : Colors.white12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (rep['reportado_id'] == null || rep['reportado_id'].toString().isEmpty)
                                                  ? 'Inconveniente general'
                                                  : 'Reportado: ${rep['reportado_nombre'] ?? ''}',
                                              style: TextStyle(
                                                color: esPendiente ? Colors.redAccent : AppTheme.textoSecundario,
                                                fontWeight: FontWeight.bold,
                                                fontSize: esAccesible ? 17 : 15,
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              (rep['creado_en'] ?? '').toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: AppTheme.textoSecundario, fontSize: esAccesible ? 14 : 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Por: ${rep['reportante_nombre'] ?? ''}',
                                        style: TextStyle(
                                            color: AppTheme.textoSecundario, fontSize: esAccesible ? 15 : 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: esPendiente
                                              ? Colors.redAccent.withValues(alpha: 0.15)
                                              : Colors.grey.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          estado,
                                          style: TextStyle(
                                            color: esPendiente ? Colors.redAccent : AppTheme.textoSecundario,
                                            fontSize: esAccesible ? 12 : 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '"${rep['motivo'] ?? ''}"',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: esAccesible ? 15 : 13,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                      if (esPendiente) ...[
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if ((rep['reportado_id'] ?? '').toString().isNotEmpty) ...[
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.acentoNaranja,
                                                  minimumSize: const Size(0, 40),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                ),
                                                onPressed: () => _suspenderUsuario(rep),
                                                icon: Icon(Icons.timer_off_outlined, size: esAccesible ? 20 : 16),
                                                label: Text('Suspender',
                                                    style: TextStyle(fontSize: esAccesible ? 14 : 12)),
                                              ),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red.shade800,
                                                  minimumSize: const Size(0, 40),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                ),
                                                onPressed: () => _darDeBajaUsuario(rep),
                                                icon: Icon(Icons.block, size: esAccesible ? 20 : 16),
                                                label: Text('Bloquear',
                                                    style: TextStyle(fontSize: esAccesible ? 14 : 12)),
                                              ),
                                            ],
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.grey,
                                                side: const BorderSide(color: Colors.grey),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                              onPressed: () => _desestimarReporte(rep),
                                              child: Text('Desestimar',
                                                  style: TextStyle(fontSize: esAccesible ? 14 : 12)),
),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                            }).toList(),
                          ),
                    const SizedBox(height: 28),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    // ================= SECCIÓN 3: SUGERENCIAS DE ESFUERZO =================
                    Text(
                      'Clasificaciones de esfuerzo cuestionadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: esAccesible ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La comunidad marcó estas publicaciones con el nivel de esfuerzo equivocado.',
                      style: TextStyle(color: AppTheme.textoSecundario, fontSize: esAccesible ? 15 : 13),
                    ),
                    const SizedBox(height: 16),

                    _sugerenciasEsfuerzo.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.superficieTarjeta,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'No hay sugerencias pendientes.',
                                style: TextStyle(color: AppTheme.textoSecundario, fontSize: esAccesible ? 16 : 14),
                              ),
                            ),
                          )
                        : Column(
                            children: _sugerenciasEsfuerzo.map<Widget>((sug) {
                              return Card(
                                color: AppTheme.superficieTarjeta,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: AppTheme.acentoNaranja.withValues(alpha: 0.4)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '"${sug['publicacion_titulo'] ?? ''}"',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: esAccesible ? 17 : 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          _chipNivel(sug['nivel_actual'], esAccesible),
                                          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textoSecundario),
                                          _chipNivel(sug['nivel_sugerido'], esAccesible, destacado: true),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Sugerido por ${sug['sugerido_por'] ?? ''} · ${sug['creado_en'] ?? ''}',
                                        style: TextStyle(color: AppTheme.textoSecundario, fontSize: esAccesible ? 14 : 12),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.acentoVerdeEco,
                                                minimumSize: const Size(0, 40),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                              onPressed: () => _aplicarSugerencia(sug),
                                              icon: Icon(Icons.check_rounded, size: esAccesible ? 20 : 16, color: Colors.black),
                                              label: Text('Aplicar',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.black, fontSize: esAccesible ? 14 : 12)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.grey,
                                                side: const BorderSide(color: Colors.grey),
                                                minimumSize: const Size(0, 40),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                              onPressed: () => _descartarSugerencia(sug),
                                              child: Text('Descartar',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: esAccesible ? 14 : 12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
),
                                );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _chipNivel(dynamic nivel, bool esAccesible, {bool destacado = false}) {
    final String texto = (nivel ?? '').toString();
    Color color;
    switch (texto) {
      case 'SIMPLE':
        color = AppTheme.acentoVerdeEco;
        break;
      case 'MEDIO':
        color = AppTheme.acentoAzulTurquesa;
        break;
      case 'ALTO':
        color = AppTheme.acentoNaranja;
        break;
      default:
        color = AppTheme.textoSecundario;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: destacado ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: destacado ? 1.5 : 1),
      ),
      child: Text(
        destacado ? 'Sugerido: $texto' : 'Ahora: $texto',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: esAccesible ? 13 : 11,
        ),
      ),
    );
  }

  Widget _buildTarjetaKpi(String titulo, String valor, IconData icono, Color color, bool esAccesible) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.superficieTarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: esAccesible ? 32 : 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valor,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: esAccesible ? 22 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    titulo,
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: esAccesible ? 13 : 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraGrafico(String dia, double porcentaje, bool esAccesible) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 90 * porcentaje,
          width: 16,
          decoration: BoxDecoration(
            color: AppTheme.acentoVerdeEco,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dia,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textoSecundario,
            fontSize: esAccesible ? 13 : 11,
          ),
        ),
      ],
    );
  }
}
