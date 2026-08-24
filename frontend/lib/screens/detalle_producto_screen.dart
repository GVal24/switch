import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class DetalleProductoScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String usuarioActualId;
  final String usuarioActualNombre;

  const DetalleProductoScreen({
    Key? key,
    required this.item,
    required this.usuarioActualId,
    required this.usuarioActualNombre,
  }) : super(key: key);

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  final Set<String> _idsSeleccionados = {};
  List<dynamic> _misPublicacionesDisponibles = [];
  bool _cargandoMisPublicaciones = false;

  @override
  void initState() {
    super.initState();
    _cargarMisPublicaciones();
  }

  Future<void> _cargarMisPublicaciones() async {
    setState(() => _cargandoMisPublicaciones = true);
    // Solo publicaciones activas propias (el id viene del token en el servidor)
    final resultado = await ApiService.obtenerMisPublicaciones();
    if (!mounted) return;
    final idDeseada = (widget.item['id'] ?? '').toString();
    setState(() {
      _misPublicacionesDisponibles =
          resultado.where((p) => (p['id'] ?? '').toString() != idDeseada).toList();
      _cargandoMisPublicaciones = false;
    });
  }

  Future<void> _procesarPropuestaYNavegar() async {
    final oferenteId = (widget.item['oferente_id'] ?? widget.item['oferenteId'] ?? widget.item['usuario_id'] ?? '').toString();
    final oferenteNombre = widget.item['oferente_nombre'] ?? widget.item['oferenteNombre'] ?? 'Usuario';

    final res = await ApiService.proponerSwitch(
      publicacionDeseadaId: (widget.item['id'] ?? '').toString(),
      idsOfrecidos: _idsSeleccionados.toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['mensaje'] ?? ''),
        backgroundColor: res['exito'] == true ? AppTheme.acentoVerdeEco : Colors.redAccent,
      ),
    );

    if (res['exito'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            usuarioActualId: widget.usuarioActualId,
            receptorId: oferenteId,
            receptorNombre: oferenteNombre,
          ),
        ),
      );
    }
  }

  void _mostrarDialogoReporte() {
    final motivoController = TextEditingController();
    final oferenteId = (widget.item['oferente_id'] ?? widget.item['oferenteId'] ?? widget.item['usuario_id'] ?? '2').toString();
    final oferenteNombre = widget.item['oferente_nombre'] ?? widget.item['oferenteNombre'] ?? 'Usuario';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colorTarjeta,
        title: Text('Reportar Usuario', style: TextStyle(color: context.colorTexto)),
        content: TextField(
          controller: motivoController,
          style: TextStyle(color: context.colorTexto),
          decoration: InputDecoration(
              hintText: 'Motivo del reporte...',
              hintStyle: TextStyle(color: context.colorTextoSuave)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.reportarUsuario(
                reportanteId: widget.usuarioActualId,
                reportanteNombre: widget.usuarioActualNombre,
                reportadoId: oferenteId,
                reportadoNombre: oferenteNombre,
                motivo: motivoController.text,
              );
            },
            child: const Text('REPORTAR'),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoSugerirEsfuerzo() {
    String nivelElegido = 'MEDIO';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.colorTarjeta,
          title: Text('¿El esfuerzo está mal clasificado?',
              style: TextStyle(color: context.colorTexto, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contanos cuánto esfuerzo real te parece que implica:',
                style: TextStyle(color: context.colorTextoSuave, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...['SIMPLE', 'MEDIO', 'ALTO'].map(
                (nivel) => RadioListTile<String>(
                  value: nivel,
                  groupValue: nivelElegido,
                  activeColor: AppTheme.acentoVerdeEco,
                  title: Text(nivel, style: TextStyle(color: _obtenerColorEsfuerzo(nivel), fontWeight: FontWeight.bold)),
                  onChanged: (v) => setDialogState(() => nivelElegido = v ?? 'MEDIO'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await ApiService.sugerirEsfuerzo(
                  publicacionId: (widget.item['id'] ?? '').toString(),
                  nivelSugerido: nivelElegido,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['mensaje'] ?? ''),
                    backgroundColor: res['exito'] == true ? AppTheme.acentoVerdeEco : Colors.redAccent,
                  ),
                );
              },
              child: const Text('ENVIAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalProponerSwitch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorTarjeta,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => StatefulBuilder(
        builder: (builderContext, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(builderContext).size.height * 0.8,
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proponer Switch por:\n"${widget.item['titulo']}"',
                  style: TextStyle(
                      color: context.colorTexto,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elegí qué ofrecés a cambio (solo publicaciones de tu catálogo):',
                  style: TextStyle(color: context.colorTextoSuave, fontSize: 13),
                ),
                Divider(color: context.colorTextoSuave.withValues(alpha: 0.25), height: 24),

                Expanded(
                  child: _cargandoMisPublicaciones
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.acentoVerdeEco))
                      : _misPublicacionesDisponibles.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  '¡Todavía no tenés publicaciones activas!\n\nCargá un objeto o servicio en el catálogo para poder ofrecerlo a cambio.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: context.colorTextoSuave, fontSize: 14),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _misPublicacionesDisponibles.length,
                              itemBuilder: (ctx, idx) {
                                final miItem = _misPublicacionesDisponibles[idx];
                                final String titulo = miItem['titulo'] ?? '';
                                final String desc = miItem['descripcion'] ?? '';
                                final String? imagen = miItem['imagen_url'] ?? miItem['imagenUrl'];
                                final String idPub = (miItem['id'] ?? '').toString();
                                final bool estaSeleccionado = _idsSeleccionados.contains(idPub);

                                return CheckboxListTile(
                                  activeColor: AppTheme.acentoVerdeEco,
                                  checkColor: Colors.black,
                                  secondary: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: (imagen != null && imagen.isNotEmpty)
                                          ? Image.network(
                                              imagen,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: context.colorTarjeta,
                                                child: const Icon(Icons.inventory_2_outlined,
                                                    color: AppTheme.acentoVerdeEco, size: 24),
                                              ),
                                            )
                                          : Container(
                                              color: context.colorTarjeta,
                                              child: const Icon(Icons.inventory_2_outlined,
                                                  color: AppTheme.acentoVerdeEco, size: 24),
                                            ),
                                    ),
                                  ),
                                  title: Text(titulo, style: TextStyle(color: context.colorTexto, fontWeight: FontWeight.bold)),
                                  subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.colorTextoSuave)),
                                  value: estaSeleccionado,
                                  onChanged: (bool? valor) {
                                    setModalState(() {
                                      if (valor == true) {
                                        _idsSeleccionados.add(idPub);
                                      } else {
                                        _idsSeleccionados.remove(idPub);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_misPublicacionesDisponibles.isEmpty || _idsSeleccionados.isEmpty)
                        ? null
                        : () {
                            Navigator.pop(modalContext);
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _procesarPropuestaYNavegar();
                            });
                          },
                    child: Text(
                      _misPublicacionesDisponibles.isEmpty
                          ? 'PUBLICÁ ALGO PRIMERO EN EL CATÁLOGO'
                          : _idsSeleccionados.isEmpty
                              ? 'SELECCIONÁ AL MENOS UNA PUBLICACIÓN'
                              : 'ENVIAR PROPUESTA (${_idsSeleccionados.length} SELECCIONADO/S)',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagenHeader(String? url, String? titulo) {
    if (url != null && url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
      return Container(
        height: 230,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: context.colorTarjeta,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImagen(titulo),
        ),
      );
    }
    return _buildPlaceholderImagen(titulo);
  }

  Widget _buildPlaceholderImagen(String? titulo) {
    IconData icono = Icons.inventory_2_outlined;
    final titleLower = (titulo ?? '').toLowerCase();

    if (titleLower.contains('libro') || titleLower.contains('manual')) {
      icono = Icons.menu_book_rounded;
    } else if (titleLower.contains('herramienta') || titleLower.contains('taladro')) {
      icono = Icons.build_rounded;
    } else if (titleLower.contains('ropa') || titleLower.contains('campera')) {
      icono = Icons.checkroom_rounded;
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.acentoAzulTurquesa.withValues(alpha: 0.3),
            context.colorTarjeta,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: AppTheme.acentoVerdeEco),
          const SizedBox(height: 10),
          Text(
            'Switch P2P • Publicación Oficial',
            style: TextStyle(
                fontSize: 13,
                color: context.colorTextoSuave,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtituloOferente(Map<String, dynamic> item) {
    final impacto = item['autor_impacto'];
    final nivel = impacto?['nivel'];
    if (nivel == null) {
      return Text(
        'Miembro de la comunidad',
        style: TextStyle(color: context.colorTextoSuave, fontSize: 12),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, size: 14, color: AppTheme.acentoVerdeEco),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Nivel ${nivel['numero']}: ${nivel['nombre']}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.acentoVerdeEco, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Color _obtenerColorEsfuerzo(String? nivel) {
    switch (nivel) {
      case 'SIMPLE':
        return AppTheme.acentoVerdeEco;
      case 'MEDIO':
        return AppTheme.acentoAzulTurquesa;
      case 'ALTO':
        return AppTheme.acentoNaranja;
      default:
        return context.colorTextoSuave;
    }
  }

  @override
  Widget build(BuildContext context) {
    final oferenteId = (widget.item['oferente_id'] ?? widget.item['oferenteId'] ?? widget.item['usuario_id'] ?? '2').toString();
    final oferenteNombre = widget.item['oferente_nombre'] ?? widget.item['oferenteNombre'] ?? 'Vecino/a';
    final String? imagenUrl = widget.item['imagen_url'] ?? widget.item['imagenUrl'];
    final String nivelEsfuerzo = widget.item['nivel_esfuerzo'] ?? widget.item['nivelEsfuerzo'] ?? 'SIMPLE';
    final Color colorEsfuerzo = _obtenerColorEsfuerzo(nivelEsfuerzo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Publicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            onPressed: _mostrarDialogoReporte,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagenHeader(imagenUrl, widget.item['titulo']),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorEsfuerzo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorEsfuerzo, width: 1.2),
                ),
                child: Text(
                  'Nivel de Esfuerzo: $nivelEsfuerzo',
                  style: TextStyle(
                      color: colorEsfuerzo,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _mostrarDialogoSugerirEsfuerzo,
                  icon: Icon(Icons.rate_review_outlined, size: 16, color: context.colorTextoSuave),
                  label: Text(
                    '¿Está mal clasificado? Sugerí el nivel correcto',
                    style: TextStyle(color: context.colorTextoSuave, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.item['titulo'] ?? 'Sin Título',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Descripción del Producto',
                style: TextStyle(
                  color: context.colorTextoSuave,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colorTarjeta,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.item['descripcion'] ?? 'Sin descripción detallada disponible.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: context.colorTarjeta,
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.acentoAzulTurquesa,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  'Ofrecido por $oferenteNombre',
                  style: TextStyle(color: context.colorTexto, fontWeight: FontWeight.bold),
                ),
                subtitle: _buildSubtituloOferente(widget.item),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.acentoVerdeEco),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        usuarioActualId: widget.usuarioActualId,
                        receptorId: oferenteId,
                        receptorNombre: oferenteNombre,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _mostrarModalProponerSwitch,
                  icon: const Icon(Icons.swap_horizontal_circle_outlined),
                  label: const Text('PROPONER UN SWITCH (TRUEQUE)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}