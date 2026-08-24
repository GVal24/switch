import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MisTruequesScreen extends StatefulWidget {
  final String usuarioActualId;
  final String usuarioActualNombre;

  const MisTruequesScreen({
    super.key,
    required this.usuarioActualId,
    required this.usuarioActualNombre,
  });

  @override
  State<MisTruequesScreen> createState() => _MisTruequesScreenState();
}

class _MisTruequesScreenState extends State<MisTruequesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _recibidas = [];
  List<dynamic> _enviadas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarPropuestas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPropuestas() async {
    setState(() => _cargando = true);
    final datos = await ApiService.obtenerMisPropuestas();
    if (!mounted) return;
    setState(() {
      _recibidas = (datos?['recibidas'] as List<dynamic>?) ?? [];
      _enviadas = (datos?['enviadas'] as List<dynamic>?) ?? [];
      _cargando = false;
    });
  }

  // ==========================================
  // Acciones
  // ==========================================
  Future<void> _responder(Map propuesta, String estado) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(estado == 'ACEPTADA' ? '¿Aceptar trueque?' : '¿Rechazar propuesta?'),
        content: Text(
          estado == 'ACEPTADA'
              ? 'Se aceptará la propuesta de ${propuesta['ofertante_nombre']} por "${propuesta['titulo_deseado']}". Las demás propuestas pendientes sobre esta publicación se rechazarán automáticamente.'
              : 'La propuesta de ${propuesta['ofertante_nombre']} será rechazada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  estado == 'ACEPTADA' ? AppTheme.acentoVerdeEco : Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(estado == 'ACEPTADA' ? 'Aceptar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final resultado =
        await ApiService.responderPropuesta(propuesta['id'].toString(), estado);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['mensaje'] ?? ''),
        backgroundColor: resultado['exito'] == true ? AppTheme.acentoVerdeEco : Colors.redAccent,
      ),
    );
    _cargarPropuestas();
  }

  Future<void> _confirmarTrueque(Map propuesta) async {
    int puntajeSeleccionado = 5;
    final comentarioController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Confirmar trueque'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Se concretó este trueque? Al confirmar ambas partes quedará completado.',
              ),
              const SizedBox(height: 16),
              const Text('¿Cómo calificás a la otra persona?'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < puntajeSeleccionado ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setStateDialog(() => puntajeSeleccionado = index + 1),
                  );
                }),
              ),
              TextField(
                controller: comentarioController,
                maxLength: 120,
                decoration: const InputDecoration(
                  hintText: 'Comentario (opcional)',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.acentoVerdeEco,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) return;

    final resultado = await ApiService.confirmarTrueque(
      propuesta['id'].toString(),
      puntaje: puntajeSeleccionado,
      comentario: comentarioController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['mensaje'] ?? ''),
        backgroundColor: resultado['exito'] == true ? AppTheme.acentoVerdeEco : Colors.redAccent,
      ),
    );
    _cargarPropuestas();
  }

  // ==========================================
  // UI
  // ==========================================
  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange.shade700;
      case 'ACEPTADA':
        return AppTheme.acentoAzulTurquesa;
      case 'COMPLETADO':
        return AppTheme.acentoVerdeEco;
      case 'RECHAZADA':
      default:
        return Colors.redAccent;
    }
  }

  String _etiquetaEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'ACEPTADA':
        return 'Aceptada';
      case 'COMPLETADO':
        return 'Completado';
      case 'RECHAZADA':
      default:
        return 'Rechazada';
    }
  }

  Widget _tarjetaPropuesta(Map p) {
    final items = (p['items_ofrecidos'] as List<dynamic>? ?? [])
        .map((e) => e['titulo'].toString())
        .join(', ');
    final esDueno = p['dueno_id'].toString() == widget.usuarioActualId;
    final yaConfirme = esDueno
        ? (p['confirmacion_dueno'] == true)
        : (p['confirmacion_ofertante'] == true);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p['titulo_deseado']?.toString().isNotEmpty == true
                        ? p['titulo_deseado']
                        : 'Publicación',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colorEstado(p['estado']).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _etiquetaEstado(p['estado']),
                    style: TextStyle(
                      color: _colorEstado(p['estado']),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              esDueno
                  ? 'Ofrecido por: ${p['ofertante_nombre']}'
                  : 'Dueño: ${p['dueno_nombre'] ?? 'Vecino'}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'A cambio de: $items',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            Text(
              'Enviada el ${p['creado_en'] ?? ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
            const SizedBox(height: 10),

            // Acciones según estado
            if (esDueno && p['estado'] == 'PENDIENTE')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      onPressed: () => _responder(p, 'RECHAZADA'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aceptar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.acentoVerdeEco,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _responder(p, 'ACEPTADA'),
                    ),
                  ),
                ],
              )
            else if ((p['estado'] == 'ACEPTADA' || p['estado'] == 'COMPLETADO') && !yaConfirme)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('Confirmar y calificar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.acentoAzulTurquesa,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _confirmarTrueque(p),
                ),
              )
            else if (yaConfirme && p['estado'] != 'COMPLETADO')
              Row(
                children: [
                  Icon(Icons.hourglass_top, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Esperando confirmación de la otra parte',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              )
            else if (p['estado'] == 'COMPLETADO' && yaConfirme)
              Row(
                children: [
                  Icon(Icons.verified, size: 16, color: AppTheme.acentoVerdeEco),
                  const SizedBox(width: 6),
                  Text(
                    'Trueque completado. ¡Gracias por confiar!',
                    style: TextStyle(
                      color: AppTheme.acentoVerdeEco,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _lista(List<dynamic> propuestas) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (propuestas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Todavía no hay propuestas acá.\n¡Explorá el catálogo y proponé un Switch!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarPropuestas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: propuestas.length,
        itemBuilder: (context, index) => _tarjetaPropuesta(
          Map<String, dynamic>.from(propuestas[index] as Map),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Trueques'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Recibidas (${_recibidas.length})'),
            Tab(text: 'Enviadas (${_enviadas.length})'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_lista(_recibidas), _lista(_enviadas)],
            ),
    );
  }
}
