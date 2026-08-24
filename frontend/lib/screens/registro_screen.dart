import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_accesibilidad.dart';
import '../widgets/logo_switch.dart';

class RegistroScreen extends StatefulWidget {
  final VoidCallback onToggleAccesibilidad;
  final bool modoAccesibleActivo;
  final VoidCallback? onAdminPressed;

  const RegistroScreen({
    Key? key,
    required this.onToggleAccesibilidad,
    required this.modoAccesibleActivo,
    this.onAdminPressed,
  }) : super(key: key);

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dniController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController(); 

  bool _esMayorEdad = false;
  bool _aceptoTerminos = false;
  bool _cargando = false;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _dniController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _mostrarTextoLegal(
      {required BuildContext context,
      required String titulo,
      required String contenido}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficieTarjeta,
        title: Text(titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.textoClaro)),
        content: SingleChildScrollView(
            child: Text(contenido,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textoSecundario))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ENTENDIDO',
                  style: TextStyle(color: AppTheme.acentoVerdeEco))),
        ],
      ),
    );
  }

  void _procesarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_esMayorEdad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Debes declarar ser mayor de 18 años para registrarte.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!_aceptoTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debes aceptar los Términos y Condiciones.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _cargando = true);

    final resultado = await ApiService.registrarUsuario(
      dni: _dniController.text.trim(),
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      password: _passwordController.text.trim(),
      aceptoTerminos: _aceptoTerminos,
      esMayorEdad: _esMayorEdad,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡Registro exitoso en Switch! Iniciá sesión para continuar.'),
            backgroundColor: AppTheme.acentoVerdeEco),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(resultado['mensaje'] ?? 'Error al registrar.'),
            backgroundColor: Colors.redAccent),
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
            Text('Registro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                Text('Unite a la comunidad',
                    style: theme.textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                    'Ingresá tus datos para colaborar con instituciones y realizar trueques P2P.',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'DNI (Sin puntos)',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder()),
                  style: theme.textTheme.bodyLarge,
                  validator: (val) => val == null || val.length < 7
                      ? 'Ingresá un DNI válido'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder()),
                  style: theme.textTheme.bodyLarge,
                  validator: (val) => val == null || val.isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder()),
                  style: theme.textTheme.bodyLarge,
                  validator: (val) => val == null || val.isEmpty
                      ? 'El apellido es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Teléfono celular',
                      prefixIcon: Icon(Icons.phone_android_outlined),
                      border: OutlineInputBorder()),
                  style: theme.textTheme.bodyLarge,
                  validator: (val) => val == null || val.isEmpty
                      ? 'El teléfono es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña (mínimo 6 caracteres)',
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
                      return 'La contraseña es obligatoria';
                    }
                    if (val.trim().length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                CheckboxListTile(
                  value: _esMayorEdad,
                  onChanged: (val) =>
                      setState(() => _esMayorEdad = val ?? false),
                  activeColor: AppTheme.acentoVerdeEco,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('Declaro ser mayor de 18 años.',
                      style: theme.textTheme.bodyLarge),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.superficieTarjeta,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10)),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _aceptoTerminos,
                        activeColor: AppTheme.acentoVerdeEco,
                        onChanged: (val) =>
                            setState(() => _aceptoTerminos = val ?? false),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontSize: 13),
                            children: [
                              const TextSpan(text: 'Acepto los '),
                              TextSpan(
                                text: 'Términos y Condiciones',
                                style: const TextStyle(
                                    color: AppTheme.acentoAzulTurquesa,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _mostrarTextoLegal(
                                        context: context,
                                        titulo: 'Términos y Condiciones',
                                        contenido:
                                            'Switch es una plataforma de intercambio colaborativo P2P...',
                                      ),
                              ),
                              const TextSpan(text: ' y la '),
                              TextSpan(
                                text: 'Política de Privacidad',
                                style: const TextStyle(
                                    color: AppTheme.acentoAzulTurquesa,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _mostrarTextoLegal(
                                        context: context,
                                        titulo: 'Política de Privacidad',
                                        contenido:
                                            'Tus datos son resguardados de forma estrictamente segura...',
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _cargando ? null : _procesarRegistro,
                  child: _cargando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('CREAR MI CUENTA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}