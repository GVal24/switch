import 'package:flutter/material.dart';
import 'instituciones_screen.dart';
import 'catalogo_p2p_screen.dart';
import 'accesibilidad_screen.dart';
import 'admin_dashboard_screen.dart';
import 'perfil_screen.dart';
import '../services/api_service.dart';

class AppNavigation extends StatefulWidget {
  final Map<String, dynamic>? usuarioActual;
  final VoidCallback onToggleAccesibilidad;
  final bool modoAccesibleActivo;
  final Function(Map<String, dynamic>?)? onSesionCambiada;

  const AppNavigation({
    Key? key,
    this.usuarioActual,
    required this.onToggleAccesibilidad,
    required this.modoAccesibleActivo,
    this.onSesionCambiada,
  }) : super(key: key);

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _indiceActual = 0;
  bool _adminAutenticado = false;

  @override
  void initState() {
    super.initState();
    _verificarEstadoAdmin();
  }

  @override
  void didUpdateWidget(covariant AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usuarioActual != oldWidget.usuarioActual) {
      _verificarEstadoAdmin();
    }
  }

  void _verificarEstadoAdmin() {
    final bool esAdmin =
        widget.usuarioActual != null && widget.usuarioActual!['rol'] == 'ADMIN';
    if (_adminAutenticado != esAdmin) {
      setState(() => _adminAutenticado = esAdmin);
    }
  }

  void _cerrarSesionAdmin() {
    setState(() {
      _adminAutenticado = false;
      _indiceActual = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión de administración cerrada.'),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  void _mostrarLoginAdmin() {
    final usuarioController = TextEditingController();
    final contraController = TextEditingController();
    bool ingresando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final bool esPaletaClara = Theme.of(ctx).brightness == Brightness.light;
          final Color colorFondo = esPaletaClara ? const Color(0xFFF6F3EE) : const Color(0xFF1a1a2e);
          final Color colorTexto = esPaletaClara ? const Color(0xFF4A4A45) : Colors.white;
          final Color colorSubtitulo = esPaletaClara ? const Color(0xFF8A877E) : const Color(0xFF888888);
          return AlertDialog(
          scrollable: true,
          backgroundColor: colorFondo,
          title: Text('Acceso Admin',
              style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresá con tu cuenta de administración (DNI y contraseña).',
                style: TextStyle(color: colorSubtitulo, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usuarioController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colorTexto),
                cursorColor: colorTexto,
                decoration: InputDecoration(
                  filled: false,
                  labelText: 'DNI',
                  labelStyle: TextStyle(color: colorSubtitulo),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colorSubtitulo)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colorTexto)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contraController,
                obscureText: true,
                style: TextStyle(color: colorTexto),
                cursorColor: colorTexto,
                decoration: InputDecoration(
                  filled: false,
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: colorSubtitulo),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colorSubtitulo)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colorTexto)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCELAR', style: TextStyle(color: colorSubtitulo)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              onPressed: ingresando
                  ? null
                  : () async {
                      setStateDialog(() => ingresando = true);
                      final res = await ApiService.iniciarSesionAdmin(
                        dni: usuarioController.text.trim(),
                        password: contraController.text,
                      );
                      if (!ctx.mounted) return;
                      if (res['exito'] == true && res['usuario']?['rol'] == 'ADMIN') {
                        Navigator.pop(ctx);
                        setState(() {
                          _adminAutenticado = true;
                          _indiceActual = 4;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('¡Acceso Admin Concedido!'),
                              backgroundColor: Colors.green),
                        );
                      } else if (res['exito'] == true) {
                        setStateDialog(() => ingresando = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Esta cuenta no tiene permisos de administración.'),
                            backgroundColor: Colors.red),
                        );
                      } else {
                        setStateDialog(() => ingresando = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(res['mensaje'] ?? 'Credenciales incorrectas'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
              child: Text(ingresando ? 'INGRESANDO...' : 'INGRESAR',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
        },
      ),
    );
  }

  /// Pestaña "Mi Perfil": delega en la pantalla real de perfil,
  /// que carga las estadísticas y el impacto comunitario reales del backend.
  Widget _buildVistaPerfil() {
    return PerfilScreen(
      usuarioActual: widget.usuarioActual,
      onToggleAccesibilidad: widget.onToggleAccesibilidad,
      modoAccesibleActivo: widget.modoAccesibleActivo,
      onSesionCambiada: widget.onSesionCambiada,
      onMostrarLoginAdmin: _mostrarLoginAdmin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String usuarioActualId = (widget.usuarioActual?['id'] ?? '1').toString();
    final String usuarioActualNombre =
        (widget.usuarioActual?['nombreCompleto'] ?? widget.usuarioActual?['nombre'] ?? 'Usuario Activo')
            .toString();

    final List<Widget> pantallas = [
      InstitucionesScreen(
        onToggleAccesibilidad: widget.onToggleAccesibilidad,
        modoAccesibleActivo: widget.modoAccesibleActivo,
        usuarioActualId: usuarioActualId,
        usuarioActualNombre: usuarioActualNombre,
      ),
      CatalogoP2PScreen(
        onToggleAccesibilidad: widget.onToggleAccesibilidad,
        modoAccesibleActivo: widget.modoAccesibleActivo,
        nexoSocialActivo: false,
        usuarioActualId: usuarioActualId,
        usuarioActualNombre: usuarioActualNombre,
      ),
      _buildVistaPerfil(),
      AccesibilidadScreen(
        onToggleAccesibilidad: widget.onToggleAccesibilidad,
        modoAccesibleActivo: widget.modoAccesibleActivo,
      ),
      if (_adminAutenticado)
        AdminDashboardScreen(
          onCerrarSesion: _cerrarSesionAdmin,
        ),
    ];

    return Scaffold(
      body: pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        iconSize: widget.modoAccesibleActivo ? 32 : 24,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: widget.modoAccesibleActivo ? 15 : 12,
        ),
        onTap: (index) {
          if (index == 4 && !_adminAutenticado) {
            _mostrarLoginAdmin();
          } else if (index < pantallas.length) {
            setState(() => _indiceActual = index);
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: 'Voluntariado',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Catálogo P2P',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Mi Perfil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new),
            label: 'Accesibilidad',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}
