import 'package:flutter/material.dart';
import 'screens/app_navigation.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/accesibilidad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var sesionGuardada = await ApiService.obtenerSesionGuardada();
  // El admin NO se restaura como sesión "de vecino": si quedó persistida
  // (login admin del diálogo), se descarta para que la app arranque limpia
  // y el acceso admin se haga siempre por el botón "Acceso Administración".
  if (sesionGuardada != null && sesionGuardada['rol'] == 'ADMIN') {
    await ApiService.cerrarSesion();
    sesionGuardada = null;
  }
  await AccesibilidadService.instancia.cargar();
  runApp(SwitchApp(sesionInicial: sesionGuardada));
}

class SwitchApp extends StatefulWidget {
  final Map<String, dynamic>? sesionInicial;

  const SwitchApp({Key? key, this.sesionInicial}) : super(key: key);

  @override
  State<SwitchApp> createState() => _SwitchAppState();
}

class _SwitchAppState extends State<SwitchApp> {
  bool _modoAccesibleActivo = false;
  Map<String, dynamic>? _usuarioActual;
  final AccesibilidadService _acc = AccesibilidadService.instancia;

  @override
  void initState() {
    super.initState();
    _usuarioActual = widget.sesionInicial;
    // Reconstruye la app cuando cambia cualquier preferencia de accesibilidad
    _acc.escalaTexto.addListener(_reconstruir);
    _acc.altoContraste.addListener(_reconstruir);
    _acc.paletaSuave.addListener(_reconstruir);
    _acc.blancoNegro.addListener(_reconstruir);
  }

  @override
  void dispose() {
    _acc.escalaTexto.removeListener(_reconstruir);
    _acc.altoContraste.removeListener(_reconstruir);
    _acc.paletaSuave.removeListener(_reconstruir);
    _acc.blancoNegro.removeListener(_reconstruir);
    super.dispose();
  }

  void _reconstruir() {
    if (mounted) setState(() {});
  }

  void _toggleAccesibilidad() {
    setState(() {
      _modoAccesibleActivo = !_modoAccesibleActivo;
    });
  }

  void _actualizarSesion(Map<String, dynamic>? nuevoUsuario) {
    setState(() {
      _usuarioActual = nuevoUsuario;
    });
  }

  /// Elige el tema según las preferencias de accesibilidad activas.
  ThemeData _temaActual(bool modoAccesibleRapido) {
    if (_acc.altoContraste.value) return AppTheme.temaAltoContraste;
    if (_acc.paletaSuave.value) return AppTheme.temaPaletaSuave;
    if (modoAccesibleRapido) return AppTheme.temaVistaAccesible;
    return AppTheme.temaEstandar;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _acc.escalaTexto,
      builder: (context, escala, _) {
        return MaterialApp(
          title: 'Switch',
          debugShowCheckedModeBanner: false,
          theme: _temaActual(_modoAccesibleActivo),
          builder: (context, child) {
            Widget contenido = MediaQuery(
              // Escala de texto global para baja visión
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(escala),
              ),
              child: child ?? const SizedBox.shrink(),
            );
            // Filtro de blanco y negro puro (elimina los tonos de color)
            if (_acc.blancoNegro.value) {
              contenido = ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: contenido,
              );
            }
            return contenido;
          },
          home: AppNavigation(
            usuarioActual: _usuarioActual,
            modoAccesibleActivo: _modoAccesibleActivo,
            onToggleAccesibilidad: _toggleAccesibilidad,
            onSesionCambiada: _actualizarSesion,
          ),
          routes: {
            '/login': (context) => LoginScreen(
                  modoAccesibleActivo: _modoAccesibleActivo,
                  onToggleAccesibilidad: _toggleAccesibilidad,
                  onSesionIniciada: (user) {
                    _actualizarSesion(user);
                    Navigator.pop(context);
                  },
                ),
          },
        );
      },
    );
  }
}
