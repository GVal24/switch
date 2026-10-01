import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_accesibilidad.dart';
import '../widgets/logo_switch.dart';
import 'chat_screen.dart';
import 'qr_scanner_screen.dart';
import 'registro_institucion_screen.dart';

class InstitucionesScreen extends StatefulWidget {
  final VoidCallback onToggleAccesibilidad;
  final bool modoAccesibleActivo;
  final String usuarioActualId;
  final String usuarioActualNombre;
  final Function(bool)? onHabilitacionCambiada;

  const InstitucionesScreen({
    Key? key,
    required this.onToggleAccesibilidad,
    required this.modoAccesibleActivo,
    this.usuarioActualId = '1',
    this.usuarioActualNombre = 'Usuario Activo',
    this.onHabilitacionCambiada,
  }) : super(key: key);

  @override
  State<InstitucionesScreen> createState() => _InstitucionesScreenState();
}

class _InstitucionesScreenState extends State<InstitucionesScreen> {
  bool _cargando = true;
  bool _nexoActivo = false;
  List<dynamic> _instituciones = [];

  @override
  void initState() {
    super.initState();
    _cargarInstituciones();
  }

  Future<void> _cargarInstituciones() async {
    setState(() => _cargando = true);
    final lista = await ApiService.obtenerInstituciones();

    for (var inst in lista) {
      final cupos =
          await ApiService.obtenerCuposPorInstitucion(inst['id'].toString());
      inst['cupos'] = cupos;
    }

    if (!mounted) return;
    setState(() {
      _instituciones = lista;
      _cargando = false;
    });
  }

  // 🟢 Abre la cámara para escanear el QR físico de la institución y valida
  // la presencia con el GPS real del teléfono. Devuelve true si se activó.
  Future<bool> _validarPresencia(
      Map<String, dynamic> inst, Map<String, dynamic>? cupo) async {
    final String? qrHash = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
            nombreInstitucion: inst['nombre'] ?? 'la institución'),
      ),
    );
    if (!mounted || qrHash == null || qrHash.trim().isEmpty) return false;

    setState(() => _cargando = true);

    final res = await ApiService.validarPresenciaQR(
      usuarioId: widget.usuarioActualId,
      qrCodigoHash: qrHash.trim(),
      cupoNecesidadId: cupo != null ? cupo['id']?.toString() : null,
    );

    if (!mounted) return false;
    setState(() {
      _cargando = false;
      if (res['exito'] == true) {
        _nexoActivo = true;
        if (widget.onHabilitacionCambiada != null) {
          widget.onHabilitacionCambiada!(true);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['mensaje'] ??
            'Voluntariado y geolocalización validados con éxito.'),
        backgroundColor:
            res['exito'] == true ? AppTheme.acentoVerdeEco : Colors.redAccent,
      ),
    );
    return res['exito'] == true;
  }

  // 🟢 Valida presencia general (habilita a publicar en el catálogo).
  // Si la institución tiene varias necesidades activas, ofrece elegir cuál
  // cubrir exactamente (así solo se descuenta esa), o seguir de forma general.
  Future<void> _escanearQRValidarGeolocalizacion(
      Map<String, dynamic> inst) async {
    final String? qrHash = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
            nombreInstitucion: inst['nombre'] ?? 'la institución'),
      ),
    );
    if (!mounted || qrHash == null || qrHash.trim().isEmpty) return;

    // Necesidades activas de la institución (algunas pueden estar cubiertas)
    final List<dynamic> cupos =
        ((inst['cupos'] as List<dynamic>?) ?? []).where((c) {
      final int max = c['cupo_maximo'] ?? c['cupoMaximo'] ?? 1;
      final int actual = c['cupo_actual'] ?? c['cupoActual'] ?? 0;
      return actual < max;
    }).toList();

    // Si hay varias, mostramos un selector para que elija UNA sola y así no
    // se le suma una ayuda a todas por error.
    if (cupos.length > 1) {
      Map<String, dynamic>? cupoElegido = await _elegirNecesidad(inst, cupos);
      if (!mounted) return;
      if (cupoElegido == null) return; // canceló
      final bool esGeneral = cupoElegido['_general'] == true;
      await _validarPresencia(
        inst,
        esGeneral ? null : Map<String, dynamic>.from(cupoElegido),
      );
      await _cargarInstituciones();
      return;
    }

    // Una sola necesidad (o ninguna): validación directa.
    final Map<String, dynamic>? cupoUnico =
        cupos.length == 1 ? Map<String, dynamic>.from(cupos.first) : null;
    await _validarPresencia(inst, cupoUnico);
  }

  // Muestra las necesidades activas para que el usuario elija cuál cubrir.
  Future<Map<String, dynamic>?> _elegirNecesidad(
      Map<String, dynamic> inst, List<dynamic> cupos) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: context.colorTarjeta,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¿Qué necesidad vas a cubrir en ${inst['nombre'] ?? 'la institución'}?',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elegí UNA — solo se sumará la ayuda a esa necesidad.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: context.colorTextoSuave, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...cupos.map((cupo) {
                        final String prioridad =
                            (cupo['prioridad'] ?? 'GENERAL').toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: context.colorTextoSuave
                                      .withValues(alpha: 0.2)),
                            ),
                            title: Text(cupo['titulo'] ?? ''),
                            subtitle: Text(prioridad == 'URGENTE'
                                ? 'Necesidad urgente'
                                : prioridad == 'PRIORITARIA'
                                    ? 'Necesidad prioritaria'
                                    : 'Prioridad general'),
                            leading: Icon(
                              prioridad == 'URGENTE'
                                  ? Icons.priority_high_rounded
                                  : Icons.volunteer_activism_rounded,
                              color: prioridad == 'URGENTE'
                                  ? Colors.redAccent
                                  : AppTheme.acentoAzulTurquesa,
                            ),
                            onTap: () => Navigator.pop(ctx, cupo),
                          ),
                        );
                      }),
                      const Divider(),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: const Icon(Icons.shield_outlined,
                            color: AppTheme.acentoVerdeEco),
                        title: const Text('Solo activar habilitación'),
                        subtitle: const Text(
                            'Validar presencia sin asociar a una necesidad concreta'),
                        onTap: () => Navigator.pop(ctx, {'_general': true}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🟢 Ofrece ayuda concreta a una necesidad: escanea el QR de la institución
  // y descuenta el cupo correspondiente.
  Future<void> _ofrecerAyuda(
      Map<String, dynamic> inst, Map<String, dynamic> cupo) async {
    final exito = await _validarPresencia(inst, cupo);
    if (exito) await _cargarInstituciones();
  }

  // 🟢 Abre el chat directo con la institución para coordinar día y horario
  void _abrirChatInstitucion(Map<String, dynamic> inst, String? ayudaTitulo) {
    final institucionId = (inst['id'] ?? 'inst_1').toString();
    final institucionNombre = inst['nombre'] ?? 'Institución Voluntariado';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          usuarioActualId: widget.usuarioActualId,
          receptorId: 'inst_$institucionId',
          receptorNombre: institucionNombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            LogoSwitchIsotipo(size: 34),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Voluntariado',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        actions: [
          BotonAccesibilidad(
            modoAccesibleActivo: widget.modoAccesibleActivo,
            onPressed: widget.onToggleAccesibilidad,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarInstituciones,
          color: AppTheme.acentoVerdeEco,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner de estado de habilitación
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _nexoActivo
                        ? AppTheme.acentoVerdeEco.withValues(alpha: 0.15)
                        : AppTheme.acentoNaranja.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _nexoActivo
                          ? AppTheme.acentoVerdeEco
                          : AppTheme.acentoNaranja,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _nexoActivo
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: _nexoActivo
                            ? AppTheme.acentoVerdeEco
                            : AppTheme.acentoNaranja,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nexoActivo
                                  ? 'Habilitación ACTIVA'
                                  : 'Habilitación INACTIVA',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _nexoActivo
                                    ? AppTheme.acentoVerdeEco
                                    : AppTheme.acentoNaranja,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nexoActivo
                                  ? 'Podés publicar y solicitar intercambios P2P libremente.'
                                  : 'Colaborá en una institución para activar tu capacidad de trueque.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text('Instituciones Adheridas',
                        style: theme.textTheme.headlineLarge),
                    TextButton.icon(
                      onPressed: () async {
                        final registro = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RegistroInstitucionScreen(),
                          ),
                        );
                        if (registro == true) _cargarInstituciones();
                      },
                      icon: const Icon(Icons.add_business_rounded,
                          size: 18, color: AppTheme.acentoVerdeEco),
                      label: const Text(
                        '¿Sos una institución?',
                        style: TextStyle(
                            color: AppTheme.acentoVerdeEco,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    'Coordiná un día y horario por chat o escaneá el QR al presentarte.',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),

                if (_cargando)
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.acentoVerdeEco))
                else if (_instituciones.isEmpty)
                  const Center(
                      child: Text(
                          'No hay instituciones disponibles en este momento.'))
                else
                  ..._instituciones.map((inst) {
                    final cupos = (inst['cupos'] as List<dynamic>?) ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: context.colorTarjeta,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(inst['nombre'] ?? '',
                                    style: theme.textTheme.titleMedium),
                              ),
                              // 🟢 Botón de Chat para acordar día y horario con la institución
                              IconButton(
                                icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: AppTheme.acentoVerdeEco),
                                tooltip: 'Coordinar día y horario',
                                onPressed: () =>
                                    _abrirChatInstitucion(inst, null),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📍 ${inst['direccion']} • ${inst['tipo']}',
                            style: TextStyle(
                                color: context.colorTextoSuave, fontSize: 13),
                          ),
                          Divider(
                              height: 24,
                              color: context.colorTextoSuave
                                  .withValues(alpha: 0.25)),
                          Text('Necesidades Activas:',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (cupos.isEmpty)
                            Text(
                                'No hay cupos de necesidad abiertos por el momento.',
                                style:
                                    TextStyle(color: context.colorTextoSuave))
                          else
                            ...cupos.map((cupo) {
                              final int max = cupo['cupo_maximo'] ??
                                  cupo['cupoMaximo'] ??
                                  1;
                              final int actual = cupo['cupo_actual'] ??
                                  cupo['cupoActual'] ??
                                  0;
                              final bool estaCompleto = actual >= max;
                              final double progreso =
                                  (actual / max).clamp(0.0, 1.0);
                              final String prioridad =
                                  (cupo['prioridad'] ?? 'GENERAL').toString();
                              final Color colorPrioridad =
                                  prioridad == 'URGENTE'
                                      ? Colors.redAccent
                                      : prioridad == 'PRIORITARIA'
                                          ? Colors.orange
                                          : Colors.grey;

                              return Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.colorFondo,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: estaCompleto
                                        ? context.colorTextoSuave
                                            .withValues(alpha: 0.2)
                                        : AppTheme.acentoAzulTurquesa
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cupo['titulo'] ?? '',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              decoration: estaCompleto
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        // 🟢 Ícono para acordar ayuda puntual en esta oferta/necesidad
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          icon: const Icon(
                                              Icons.handshake_outlined,
                                              color:
                                                  AppTheme.acentoAzulTurquesa,
                                              size: 22),
                                          tooltip: 'Coordinar esta ayuda',
                                          onPressed: () =>
                                              _abrirChatInstitucion(
                                                  inst, cupo['titulo']),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: estaCompleto
                                                ? Colors.grey
                                                : AppTheme.acentoAzulTurquesa,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            estaCompleto
                                                ? 'COMPLETO'
                                                : '$actual/$max',
                                            style: TextStyle(
                                                color: context.colorTexto,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(cupo['descripcion'] ?? '',
                                        style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colorPrioridad.withValues(
                                            alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            prioridad == 'URGENTE'
                                                ? Icons.priority_high_rounded
                                                : prioridad == 'PRIORITARIA'
                                                    ? Icons.low_priority_rounded
                                                    : Icons
                                                        .check_circle_outline_rounded,
                                            size: 14,
                                            color: colorPrioridad,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            prioridad == 'GENERAL'
                                                ? 'Prioridad general'
                                                : 'Necesidad ${prioridad == 'URGENTE' ? 'urgente' : 'prioritaria'}',
                                            style: TextStyle(
                                                color: colorPrioridad,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progreso,
                                        minHeight: 8,
                                        backgroundColor: context.colorTextoSuave
                                            .withValues(alpha: 0.15),
                                        color: estaCompleto
                                            ? Colors.grey
                                            : AppTheme.acentoVerdeEco,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (!estaCompleto)
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          icon: const Icon(
                                              Icons.volunteer_activism_rounded,
                                              size: 18),
                                          label: const Text('OFRECER AYUDA'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.acentoVerdeEco,
                                            side: const BorderSide(
                                                color: AppTheme.acentoVerdeEco),
                                            minimumSize:
                                                const Size(double.infinity, 40),
                                          ),
                                          onPressed: _cargando
                                              ? null
                                              : () => _ofrecerAyuda(
                                                  inst,
                                                  Map<String, dynamic>.from(
                                                      cupo)),
                                        ),
                                      )
                                    else
                                      Row(
                                        children: [
                                          Icon(Icons.verified_rounded,
                                              size: 16,
                                              color: AppTheme.acentoVerdeEco),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Necesidad cubierta. ¡Gracias comunidad!',
                                            style: TextStyle(
                                                color: AppTheme.acentoVerdeEco,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargando
                                ? null
                                : () => _escanearQRValidarGeolocalizacion(inst),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('ESCANEAR QR'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
