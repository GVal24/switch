import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_accesibilidad.dart';
import '../widgets/logo_switch.dart';
import 'crear_publicacion_screen.dart';
import 'detalle_producto_screen.dart';
import 'perfil_screen.dart';

class CatalogoP2PScreen extends StatefulWidget {
  final VoidCallback onToggleAccesibilidad;
  final bool modoAccesibleActivo;
  final bool nexoSocialActivo;
  final String usuarioActualId;
  final String usuarioActualNombre;

  const CatalogoP2PScreen({
    Key? key,
    required this.onToggleAccesibilidad,
    required this.modoAccesibleActivo,
    this.nexoSocialActivo = false,
    this.usuarioActualId = '1',
    this.usuarioActualNombre = 'Usuario Activo',
  }) : super(key: key);

  @override
  State<CatalogoP2PScreen> createState() => _CatalogoP2PScreenState();
}

class _CatalogoP2PScreenState extends State<CatalogoP2PScreen> {
  String _filtroEsfuerzo = 'TODOS';
  String _filtroTipo = 'TODOS';
  final TextEditingController _busquedaController = TextEditingController();
  bool _cargando = true;
  List<dynamic> _publicaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogo() async {
    setState(() => _cargando = true);
    final items = await ApiService.obtenerCatalogo(
      nivelEsfuerzo: _filtroEsfuerzo == 'TODOS' ? null : _filtroEsfuerzo,
      busqueda: _busquedaController.text,
      tipoItem: _filtroTipo,
    );

    if (!mounted) return;
    setState(() {
      _publicaciones = items;
      _cargando = false;
    });
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

  Widget _buildPlaceholderCategorizado(String? titulo) {
    IconData icono = Icons.inventory_2_outlined;
    final titleLower = (titulo ?? '').toLowerCase();

    if (titleLower.contains('libro') || titleLower.contains('manual')) {
      icono = Icons.menu_book_rounded;
    } else if (titleLower.contains('herramienta') ||
        titleLower.contains('taladro')) {
      icono = Icons.build_rounded;
    } else if (titleLower.contains('ropa') || titleLower.contains('campera')) {
      icono = Icons.checkroom_rounded;
    }

    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.acentoAzulTurquesa.withValues(alpha: 0.2),
            context.colorTarjeta,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 48, color: AppTheme.acentoVerdeEco),
          const SizedBox(height: 8),
          Text(
            'Switch P2P • Trueque Colaborativo',
            style: TextStyle(
                fontSize: 12,
                color: context.colorTextoSuave,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenTarjeta(Map<dynamic, dynamic> item) {
    final String? url = item['imagen_url'] ?? item['imagenUrl'];
    final bool destacada =
        (item['autor_impacto']?['nivel']?['numero'] ?? 0) >= 4;
    Widget imagen;
    if (url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      imagen = SizedBox(
        height: 140,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildPlaceholderCategorizado(item['titulo']),
        ),
      );
    } else {
      imagen = _buildPlaceholderCategorizado(item['titulo']);
    }
    if (!destacada) return imagen;
    // Recompensa de visibilidad: publicaciones de vecinos nivel 4+ flotan
    // primero en el catálogo y muestran esta cinta.
    return Stack(
      children: [
        imagen,
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 14, color: Colors.amber.shade50),
                const SizedBox(width: 4),
                Text(
                  'DESTACADA',
                  style: TextStyle(
                    color: Colors.amber.shade50,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            Text('Switch',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        actions: [
          BotonAccesibilidad(
            modoAccesibleActivo: widget.modoAccesibleActivo,
            onPressed: widget.onToggleAccesibilidad,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final creoExitoso = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CrearPublicacionScreen(
                usuarioId: widget.usuarioActualId,
                usuarioNombre: widget.usuarioActualNombre,
              ),
            ),
          );
          if (creoExitoso == true) {
            _cargarCatalogo();
          }
        },
        backgroundColor: AppTheme.acentoVerdeEco,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('PUBLICAR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catálogo de Intercambios',
                  style: theme.textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                  'Explorá lo que tu comunidad ofrece e intercambiá libremente.',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),

              // Búsqueda por texto
              TextField(
                controller: _busquedaController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _cargarCatalogo(),
                decoration: InputDecoration(
                  hintText: 'Buscar por título o descripción...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _busquedaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _busquedaController.clear();
                            _cargarCatalogo();
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: () => _cargarCatalogo(),
                        ),
                  filled: true,
                  fillColor: context.colorTarjeta,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filtro por tipo de ítem
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['TODOS', 'OBJETO', 'SERVICIO'].map((tipo) {
                    final bool seleccionado = _filtroTipo == tipo;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: Icon(
                          tipo == 'SERVICIO'
                              ? Icons.handyman_rounded
                              : tipo == 'OBJETO'
                                  ? Icons.inventory_2_outlined
                                  : Icons.apps_rounded,
                          size: 16,
                          color: seleccionado
                              ? Colors.white
                              : context.colorTextoSuave,
                        ),
                        label: Text(
                          tipo == 'TODOS'
                              ? 'Todo'
                              : tipo[0] + tipo.substring(1).toLowerCase(),
                          style: TextStyle(
                            color: seleccionado
                                ? Colors.white
                                : context.colorTextoSuave,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: seleccionado,
                        selectedColor: AppTheme.acentoAzulTurquesa,
                        backgroundColor: context.colorTarjeta,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _filtroTipo = tipo);
                            _cargarCatalogo();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['TODOS', 'SIMPLE', 'MEDIO', 'ALTO'].map((nivel) {
                    final bool seleccionado = _filtroEsfuerzo == nivel;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          nivel == 'TODOS' ? 'Todos' : 'Nivel $nivel',
                          style: TextStyle(
                            color: seleccionado
                                ? Colors.white
                                : context.colorTextoSuave,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: seleccionado,
                        selectedColor: AppTheme.acentoVerdeEco,
                        backgroundColor: context.colorTarjeta,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _filtroEsfuerzo = nivel);
                            _cargarCatalogo();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.acentoVerdeEco))
                    : RefreshIndicator(
                        onRefresh: _cargarCatalogo,
                        color: AppTheme.acentoVerdeEco,
                        child: ListView.builder(
                          itemCount: _publicaciones.length,
                          itemBuilder: (ctx, idx) {
                            final item = _publicaciones[idx];
                            final nivelEsfuerzo = item['nivel_esfuerzo'] ??
                                item['nivelEsfuerzo'] ??
                                'SIMPLE';
                            final oferenteNombre = item['oferente_nombre'] ??
                                item['oferenteNombre'] ??
                                'Vecino/a';
                            final colorEsfuerzo =
                                _obtenerColorEsfuerzo(nivelEsfuerzo);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
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
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetalleProductoScreen(
                                        item: item,
                                        usuarioActualId: widget.usuarioActualId,
                                        usuarioActualNombre:
                                            widget.usuarioActualNombre,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildImagenTarjeta(item),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: colorEsfuerzo
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: colorEsfuerzo,
                                                      width: 1.2),
                                                ),
                                                child: Text(
                                                  'Esfuerzo $nivelEsfuerzo',
                                                  style: TextStyle(
                                                      color: colorEsfuerzo,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12),
                                                ),
                                              ),
                                              // Botón para navegar al perfil del oferente
                                              InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          PerfilScreen(
                                                        usuarioVisitado: {
                                                          'id':
                                                              (item['usuario_id'] ??
                                                                      '')
                                                                  .toString(),
                                                          'nombre':
                                                              oferenteNombre,
                                                          'trueques': item[
                                                                  'oferente_trueques'] ??
                                                              0,
                                                          'voluntariados': item[
                                                                  'oferente_voluntariados'] ??
                                                              0,
                                                          'calificacion': item[
                                                                  'oferente_calificacion'] ??
                                                              0,
                                                          'resenas': item[
                                                                  'oferente_resenas'] ??
                                                              0,
                                                          'impacto': item[
                                                              'autor_impacto'],
                                                        },
                                                        onToggleAccesibilidad:
                                                            widget
                                                                .onToggleAccesibilidad,
                                                        modoAccesibleActivo: widget
                                                            .modoAccesibleActivo,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if ((item['autor_impacto']
                                                                    ?['nivel']
                                                                ?['numero'] ??
                                                            0) >=
                                                        3) ...[
                                                      Tooltip(
                                                        message: item[
                                                                'autor_impacto']
                                                            ['nivel']['nombre'],
                                                        child: const Icon(
                                                            Icons
                                                                .verified_rounded,
                                                            color: AppTheme
                                                                .acentoVerdeEco,
                                                            size: 16),
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    const Icon(Icons.person_pin,
                                                        color: AppTheme
                                                            .acentoVerdeEco,
                                                        size: 16),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      oferenteNombre,
                                                      style: const TextStyle(
                                                        color: AppTheme
                                                            .acentoVerdeEco,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(item['titulo'] ?? '',
                                              style:
                                                  theme.textTheme.titleMedium),
                                          const SizedBox(height: 6),
                                          Text(item['descripcion'] ?? '',
                                              style: theme.textTheme.bodyLarge),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DetalleProductoScreen(
                                                    item: item,
                                                    usuarioActualId:
                                                        widget.usuarioActualId,
                                                    usuarioActualNombre: widget
                                                        .usuarioActualNombre,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons
                                                .chat_bubble_outline_rounded),
                                            label: const Text(
                                                'SOLICITAR INTERCAMBIO'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
