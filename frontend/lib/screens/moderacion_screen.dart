import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

/// Cola de moderación de Switch.
///
/// Ninguna publicación nueva queda visible desde que se crea: nace en
/// PENDIENTE_REVISION y aparece acá. Esta pantalla es la única forma de que
/// una persona mire la imagen y decida, porque el filtro automático no puede
/// distinguir de forma confiable si hay un menor de edad.
///
/// Dos tipos de revisión conviven en la misma cola:
///   - IMAGEN: hay que mirar el archivo (se abre con el token de admin).
///   - TEXTO:  no hay archivo; se revisan título y descripción.
class ModeracionScreen extends StatefulWidget {
  final bool modoAccesibleActivo;
  final VoidCallback? alCambiar;

  const ModeracionScreen({
    Key? key,
    this.modoAccesibleActivo = false,
    this.alCambiar,
  }) : super(key: key);

  @override
  State<ModeracionScreen> createState() => _ModeracionScreenState();
}

class _ModeracionScreenState extends State<ModeracionScreen> {
  List<dynamic> _cola = [];
  Map<String, dynamic> _estadisticas = {};
  bool _cargando = true;
  bool _procesando = false;
  bool _descargandoImagen = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final resultados = await Future.wait([
      AdminService.obtenerColaModeracion(),
      AdminService.obtenerEstadisticasModeracion(),
    ]);
    if (!mounted) return;
    setState(() {
      _cola = resultados[0] as List<dynamic>;
      _estadisticas = resultados[1] as Map<String, dynamic>;
      _cargando = false;
    });
  }

  bool get _esAccesible => widget.modoAccesibleActivo;

  void _avisar(String mensaje, bool exito) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TextStyle(fontSize: _esAccesible ? 16 : 14),
        ),
        backgroundColor: exito ? AppTheme.acentoVerdeEco : Colors.redAccent,
        duration: Duration(seconds: exito ? 2 : 4),
      ),
    );
  }

  // ==========================================
  // Decisiones
  // ==========================================

  Future<void> _aprobar(Map<String, dynamic> item) async {
    final esTexto = item['tipo_revision'] == 'TEXTO';
    final ok = await _confirmar(
      titulo: '¿Publicar esta publicación?',
      mensaje: esTexto
          ? 'El título y la descripción se publicarán en el catálogo. Si '
              'hay una imagen pendiente, se publicará junto con ella.'
          : 'La imagen va a salir de la cuarentena y queda accesible para '
              'todas las personas. Después de esto no se puede volver atrás '
              'desde esta pantalla.',
      textoBoton: 'SÍ, PUBLICAR',
      colorBoton: AppTheme.acentoVerdeEco,
    );
    if (ok != true) return;

    setState(() => _procesando = true);
    final res = esTexto
        ? await AdminService.aprobarTexto(_idPublicacion(item))
        : await AdminService.aprobarModeracion(_idModeracion(item));
    if (!mounted) return;
    setState(() => _procesando = false);

    _avisar(
        res['mensaje'] ?? 'Sin respuesta del servidor.', res['exito'] == true);
    if (res['exito'] == true) {
      widget.alCambiar?.call();
      _cargar();
    }
  }

  Future<void> _rechazar(Map<String, dynamic> item) async {
    final esTexto = item['tipo_revision'] == 'TEXTO';
    final motivo = await _pedirMotivo(
      titulo: '¿Por qué se rechaza?',
      ayuda: esTexto
          ? 'La publicación desaparece del catálogo. La persona que la '
              'publicó recibe el motivo.'
          : 'La publicación desaparece del catálogo y el archivo se borra '
              'del servidor.',
      textoConfirmar: 'RECHAZAR',
    );
    if (motivo == null) return;

    setState(() => _procesando = true);
    final res = esTexto
        ? await AdminService.rechazarTexto(_idPublicacion(item), motivo)
        : await AdminService.rechazarModeracion(_idModeracion(item), motivo);
    if (!mounted) return;
    setState(() => _procesando = false);

    _avisar(
        res['mensaje'] ?? 'Sin respuesta del servidor.', res['exito'] == true);
    if (res['exito'] == true) {
      widget.alCambiar?.call();
      _cargar();
    }
  }

  Future<void> _marcarComoMenor(Map<String, dynamic> item) async {
    final ok = await _confirmar(
      titulo: '¿Posible imagen de menor de edad?',
      mensaje: 'Ley 26.061. Se rechaza la publicación y se suspende la '
          'cuenta de quien la publicó.\n\n'
          'El archivo NO se borra: se conserva de forma restringida para '
          'poder remitirlo a la autoridad de protección de las infancias, y '
          'queda registrado quién hizo el hallazgo y cuándo.\n\n'
          'Sólo marcá esto si estás seguro. Si sólo tenés dudas, usá '
          '"Rechazar" y pedí una revisión más detallada.',
      textoBoton: 'SÍ, ES UN MENOR',
      colorBoton: Colors.redAccent,
    );
    if (ok != true) return;

    setState(() => _procesando = true);
    final esTexto = item['tipo_revision'] == 'TEXTO';
    final res = esTexto
        ? await AdminService.marcarTextoComoMenor(_idPublicacion(item))
        : await AdminService.marcarComoMenor(_idModeracion(item));
    if (!mounted) return;
    setState(() => _procesando = false);

    _avisar(
        res['mensaje'] ?? 'Sin respuesta del servidor.', res['exito'] == true);
    if (res['exito'] == true) {
      widget.alCambiar?.call();
      _cargar();
    }
  }

  int _idModeracion(Map<String, dynamic> item) =>
      int.tryParse((item['id'] ?? '').toString()) ?? -1;

  int _idPublicacion(Map<String, dynamic> item) =>
      int.tryParse((item['publicacion_id'] ?? '').toString()) ?? -1;

  Future<bool?> _confirmar({
    required String titulo,
    required String mensaje,
    required String textoBoton,
    required Color colorBoton,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficieTarjeta,
        title: Text(
          titulo,
          style:
              TextStyle(color: Colors.white, fontSize: _esAccesible ? 20 : 17),
        ),
        content: SingleChildScrollView(
          child: Text(
            mensaje,
            style: TextStyle(
                color: Colors.white70, fontSize: _esAccesible ? 16 : 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCELAR',
              style: TextStyle(
                  color: Colors.grey, fontSize: _esAccesible ? 16 : 13),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorBoton),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              textoBoton,
              style: TextStyle(
                color: Colors.white,
                fontSize: _esAccesible ? 16 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pedirMotivo({
    required String titulo,
    required String ayuda,
    required String textoConfirmar,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _DialogoMotivo(
        titulo: titulo,
        ayuda: ayuda,
        textoConfirmar: textoConfirmar,
        esAccesible: _esAccesible,
      ),
    );
  }

  // ==========================================
  // Ver la imagen
  // ==========================================

  Future<void> _verImagen(Map<String, dynamic> item) async {
    final id = _idModeracion(item);

    // Los bytes se piden antes de abrir el visor y no con un FutureBuilder
    // adentro: si el future se arma dentro del build, cada rebuild vuelve a
    // pedir la imagen y la pantalla entra en un bucle que no termina nunca.
    setState(() => _descargandoImagen = true);
    final bytes = await AdminService.descargarImagenModeracion(id);
    if (!mounted) return;
    setState(() => _descargandoImagen = false);

    if (bytes == null) {
      _avisar(
          'No se pudo abrir la imagen. Puede que ya no esté en el servidor.',
          false);
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.superficieTarjeta,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                item['titulo']?.toString() ?? 'Imagen a revisar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _esAccesible ? 18 : 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.memory(
                  Uint8List.fromList(bytes),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(Icons.broken_image,
                        color: Colors.white38, size: 48),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    const Text('CERRAR', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Tarjetas
  // ==========================================

  String _autoria(Map<String, dynamic> item) {
    final nombre =
        '${item['autor_nombre'] ?? ''} ${item['autor_apellido'] ?? ''}'.trim();
    final dni = (item['autor_dni'] ?? '').toString();
    if (nombre.isEmpty && dni.isEmpty) return 'Autor desconocido';
    if (dni.isEmpty) return nombre;
    return '$nombre · DNI $dni';
  }

  Widget _chip(String texto, Color color, {bool grave = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: grave ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: grave ? 1.5 : 1),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: _esAccesible ? 13 : 11,
          fontWeight: grave ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// Traduce los motivos técnicos a algo que una persona pueda entender.
  List<Widget> _marcasTecnicas(Map<String, dynamic> item) {
    final motivos = item['filtro_motivos'];
    if (motivos is! List || motivos.isEmpty) return [];

    const explicaciones = {
      'METADATOS_EXIF_ELIMINADOS':
          'Se le sacaron los datos EXIF (pueden traer GPS)',
      'METADATOS_TEXTO_PNG_ELIMINADOS': 'Se le sacaron textos incrustados',
      'FORMATO_ANIMADO': 'Es una imagen animada',
      'FORMATO_NO_RECONOCIDO': 'El archivo no es una imagen válida',
      'ARCHIVO_SOSPECHOSO_MUY_PEQUENO': 'El archivo es sospechosamente chico',
      'DIMENSIONES_MUY_PEQUENAS': 'Las medidas son demasiado chicas',
      'DIMENSIONES_EXCESIVAS': 'Las medidas son exageradamente grandes',
      'PESO_ELEVADO': 'El archivo pesa demasiado',
      'IMAGEN_ANIMADA': 'Tiene más de un cuadro',
      'ARCHIVO_ELIMINADO': 'El archivo fue eliminado del servidor',
    };

    final widgets = <Widget>[];
    for (final m in motivos) {
      final clave = m.toString();
      // Los metadatos son lo esperado: se limpian siempre, no es una alerta.
      final esRutinario = clave.startsWith('METADATOS_');
      final color =
          esRutinario ? AppTheme.acentoAzulTurquesa : AppTheme.acentoNaranja;
      widgets.add(_chip(explicaciones[clave] ?? clave, color));
    }
    return widgets;
  }

  Widget _tarjetaItem(Map<String, dynamic> item) {
    final esTexto = item['tipo_revision'] == 'TEXTO';
    final marcas = _marcasTecnicas(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficieTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['titulo']?.toString() ?? 'Sin título',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _esAccesible ? 18 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _chip(
                esTexto ? 'SIN IMAGEN' : 'CON IMAGEN',
                esTexto ? AppTheme.acentoAzulTurquesa : AppTheme.acentoVerdeEco,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item['descripcion']?.toString() ?? '',
            style: TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: _esAccesible ? 15 : 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'De: ${_autoria(item)}',
            style: TextStyle(
                color: Colors.white54, fontSize: _esAccesible ? 14 : 11),
          ),
          Text(
            'Recibido: ${item['creado_legible'] ?? 'sin fecha'}',
            style: TextStyle(
                color: Colors.white38, fontSize: _esAccesible ? 13 : 10),
          ),
          if (marcas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Lo que marcó el control automático:',
              style: TextStyle(
                color: Colors.white54,
                fontSize: _esAccesible ? 13 : 10,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            // Wrap manual porque Wrap con spacing no existe en todas las versiones.
            ..._wrap(marcas),
          ],
          const SizedBox(height: 12),
          if (!esTexto)
            OutlinedButton.icon(
              icon: _descargandoImagen
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.acentoVerdeEco),
                    )
                  : const Icon(Icons.visibility_outlined, size: 18),
              label: Text(
                _descargandoImagen ? 'ABRIENDO...' : 'VER LA IMAGEN',
                style: TextStyle(fontSize: _esAccesible ? 15 : 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.acentoVerdeEco,
                side: const BorderSide(color: AppTheme.acentoVerdeEco),
              ),
              onPressed: (_procesando || _descargandoImagen)
                  ? null
                  : () => _verImagen(item),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    'APROBAR',
                    style: TextStyle(
                      fontSize: _esAccesible ? 14 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.acentoVerdeEco,
                  ),
                  onPressed: _procesando ? null : () => _aprobar(item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(
                    'RECHAZAR',
                    style: TextStyle(
                      fontSize: _esAccesible ? 14 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                  ),
                  onPressed: _procesando ? null : () => _rechazar(item),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.report_gmailerrorred_outlined, size: 16),
              label: Text(
                'Es una imagen de menor de edad',
                style: TextStyle(fontSize: _esAccesible ? 14 : 11),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: _procesando ? null : () => _marcarComoMenor(item),
            ),
          ),
        ],
      ),
    );
  }

  /// Arma filas de chips que no se cortan a la mitad.
  List<Widget> _wrap(List<Widget> children) {
    final filas = <Widget>[];
    var fila = <Widget>[];
    for (final chip in children) {
      fila.add(
        Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 6), child: chip),
      );
      if (fila.length == 2) {
        filas.add(Wrap(children: fila));
        fila = <Widget>[];
      }
    }
    if (fila.isNotEmpty) filas.add(Wrap(children: fila));
    return filas;
  }

  // ==========================================
  // Pantalla
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final totalPendientes = _estadisticas['pendientes'] ?? _cola.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Revisión de publicaciones',
          style: TextStyle(fontSize: _esAccesible ? 20 : 17),
        ),
        actions: [
          if (totalPendientes > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.acentoNaranja,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalPendientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _esAccesible ? 18 : 14,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh, size: _esAccesible ? 28 : 24),
            tooltip: 'Actualizar',
            onPressed: _cargar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.acentoVerdeEco))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: AppTheme.acentoVerdeEco,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.acentoAzulTurquesa.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.acentoAzulTurquesa
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'El filtro automático revisa el formato del archivo y le '
                        'saca los datos de ubicación. NO puede detectar si hay '
                        'un menor de edad: eso lo decide una persona, mirando '
                        'la imagen.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _esAccesible ? 15 : 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_estadisticas.isNotEmpty) ...[
                      Text(
                        'Historial de la moderación',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _esAccesible ? 18 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aprobadas: ${_estadisticas['aprobadas'] ?? 0}   ·   '
                        'Rechazadas: ${_estadisticas['rechazadas'] ?? 0}   ·   '
                        'Con menores: ${_estadisticas['con_menores'] ?? 0}',
                        style: TextStyle(
                          color: AppTheme.textoSecundario,
                          fontSize: _esAccesible ? 14 : 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      _cola.isEmpty
                          ? 'No hay nada esperando revisión'
                          : 'Esperando tu decisión (${_cola.length})',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _esAccesible ? 18 : 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_cola.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.acentoVerdeEco,
                              size: 44,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Todo revisado. No hay publicaciones esperando.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: _esAccesible ? 15 : 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._cola
                          .map((e) => _tarjetaItem(e as Map<String, dynamic>)),
                    if (_procesando)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.acentoVerdeEco),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Pide el motivo del rechazo.
///
/// Es un StatefulWidget a propósito: el `TextEditingController` se libera en
/// su propio `dispose`. Si se crea en la pantalla y se destruye apenas vuelve
/// el `showDialog`, el `TextField` sigue montado durante la animación de
/// cierre y revienta con "A TextEditingController was used after being
/// disposed".
class _DialogoMotivo extends StatefulWidget {
  final String titulo;
  final String ayuda;
  final String textoConfirmar;
  final bool esAccesible;

  const _DialogoMotivo({
    required this.titulo,
    required this.ayuda,
    required this.textoConfirmar,
    required this.esAccesible,
  });

  @override
  State<_DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<_DialogoMotivo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.superficieTarjeta,
      title: Text(
        widget.titulo,
        style: TextStyle(
            color: Colors.white, fontSize: widget.esAccesible ? 20 : 17),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ayuda,
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: widget.esAccesible ? 15 : 12),
            ),
            const SizedBox(height: 14),
            // Alto explícito: dentro de un AlertDialog el TextField recibe
            // altura libre y el diálogo termina desbordando la pantalla.
            SizedBox(
              height: widget.esAccesible ? 140 : 110,
              child: TextField(
                controller: _controller,
                maxLines: 3,
                maxLength: 200,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Escribí el motivo',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.acentoNaranja),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCELAR',
            style: TextStyle(
                color: Colors.grey, fontSize: widget.esAccesible ? 16 : 13),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            final texto = _controller.text.trim();
            if (texto.isEmpty) return;
            Navigator.pop(context, texto);
          },
          child: Text(
            widget.textoConfirmar,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
