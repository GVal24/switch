import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_accesibilidad.dart';
import '../widgets/logo_switch.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleAccesibilidad;
  final bool modoAccesibleActivo;
  final VoidCallback? onAdminPressed;
  final Function(Map<String, dynamic>)? onSesionIniciada;

  const LoginScreen({
    Key? key,
    required this.onToggleAccesibilidad,
    required this.modoAccesibleActivo,
    this.onAdminPressed,
    this.onSesionIniciada,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _cargando = false;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _hacerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final resultado = await ApiService.iniciarSesion(
      dni: _dniController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['mensaje'] ?? '¡Bienvenido/a de nuevo!'),
          backgroundColor: AppTheme.acentoVerdeEco,
        ),
      );

      final usuarioData = resultado['usuario'] ?? {
        'id': 'usr_${_dniController.text.trim()}',
        'nombre': 'Usuario Switch',
        'dni': _dniController.text.trim(),
      };

      if (widget.onSesionIniciada != null) {
        widget.onSesionIniciada!(usuarioData);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['mensaje'] ?? 'Credenciales incorrectas.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
            Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Iniciar Sesión', style: theme.textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Ingresá tu DNI y contraseña para ingresar a tu cuenta de Switch.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de DNI (Sin puntos)',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  style: theme.textTheme.bodyLarge,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresá tu DNI';
                    }
                    if (val.trim().length < 7) {
                      return 'Ingresá un DNI válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _ocultarPassword = !_ocultarPassword);
                      },
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresá tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _cargando ? null : _hacerLogin,
                  child: _cargando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('INGRESAR'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tenés una cuenta? ', style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegistroScreen(
                              onToggleAccesibilidad: widget.onToggleAccesibilidad,
                              modoAccesibleActivo: widget.modoAccesibleActivo,
                              onAdminPressed: widget.onAdminPressed,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Registrate acá',
                        style: TextStyle(
                          color: AppTheme.acentoVerdeEco,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                if (widget.onAdminPressed != null)
                  TextButton.icon(
                    onPressed: widget.onAdminPressed,
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
                    label: const Text(
                      'Acceso Administrador',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}