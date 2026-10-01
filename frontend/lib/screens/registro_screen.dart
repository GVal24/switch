import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_accesibilidad.dart';
import '../widgets/legal_document_dialog.dart';
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

enum _Paso { datos, verificarCodigo, aceptarTerminos }

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formOtpKey = GlobalKey<FormState>();

  final _dniController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codigoController = TextEditingController();

  _Paso _paso = _Paso.datos;

  bool _esMayorEdad = false;
  bool _aceptoTerminos = false;
  bool _aceptoPrivacidad = false;

  bool _cargando = false;
  bool _ocultarPassword = true;

  // Estado de la verificación del teléfono
  String? _tokenVerificacion;
  String? _canalEnviado;
  int _minutosValidez = 10;
  int _maxIntentos = 5;
  bool _codigoMockVisible = false;
  String? _codigoMock;
  int _segundosParaReenviar = 0;
  Timer? _temporizador;

  @override
  void dispose() {
    _dniController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _codigoController.dispose();
    _temporizador?.cancel();
    super.dispose();
  }

  // ==========================================
  // Verificación del teléfono
  // ==========================================

  void _iniciarCuentaAtras(int segundos) {
    _temporizador?.cancel();
    if (segundos <= 0) return;
    setState(() => _segundosParaReenviar = segundos);
    _temporizador = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _segundosParaReenviar = _segundosParaReenviar - 1);
      if (_segundosParaReenviar <= 0) t.cancel();
    });
  }

  Future<void> _pedirCodigo({String? canalPreferido}) async {
    final telefono = _telefonoController.text.trim();
    if (telefono.isEmpty) {
      _avisar('Ingresá tu número de celular.');
      return;
    }

    setState(() => _cargando = true);

    final resultado = await ApiService.enviarCodigoOtp(
      telefono: telefono,
      canalPreferido: canalPreferido,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      setState(() {
        _paso = _Paso.verificarCodigo;
        _canalEnviado = resultado['canalEnviado']?.toString();
        _minutosValidez = (resultado['minutosValidez'] as num?)?.toInt() ?? 10;
        _maxIntentos = (resultado['maxIntentos'] as num?)?.toInt() ?? 5;
        _codigoMockVisible = resultado['esMock'] == true;
        _codigoMock = resultado['codigoMock']?.toString();
        _codigoController.clear();
      });

      final espera = (resultado['segundosRestantes'] as num?)?.toInt() ?? 60;
      _iniciarCuentaAtras(espera);

      _avisar(
        resultado['mensaje'] ??
            'Te enviamos un código por ${_canalEnviado ?? "SMS"}.',
        exito: true,
      );
    } else {
      final espera = (resultado['segundosRestantes'] as num?)?.toInt();
      if (espera != null && espera > 0) _iniciarCuentaAtras(espera);
      _avisar(resultado['mensaje'] ?? 'No pudimos enviar el código.');
    }
  }

  Future<void> _verificarCodigo() async {
    if (!_formOtpKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final resultado = await ApiService.verificarCodigoOtp(
      telefono: _telefonoController.text.trim(),
      codigo: _codigoController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true && resultado['tokenVerificacion'] != null) {
      _temporizador?.cancel();
      setState(() {
        _tokenVerificacion = resultado['tokenVerificacion'].toString();
        _paso = _Paso.aceptarTerminos;
        _segundosParaReenviar = 0;
      });
      _avisar('Teléfono verificado. Leé los términos para continuar.',
          exito: true);
    } else {
      _avisar(resultado['mensaje'] ?? 'El código no es válido.');
    }
  }

  void _volverAEditarTelefono() {
    _temporizador?.cancel();
    setState(() {
      _paso = _Paso.datos;
      _tokenVerificacion = null;
      _segundosParaReenviar = 0;
      _codigoMockVisible = false;
      _codigoMock = null;
    });
  }

  // ==========================================
  // Aceptación y alta
  // ==========================================

  void _abrirDocumento(String id, String titulo) {
    showDialog(
      context: context,
      builder: (_) => LegalDocumentDialog(
        idDocumento: id,
        tituloRespaldo: titulo,
      ),
    );
  }

  Future<void> _procesarRegistro() async {
    if (!_esMayorEdad) {
      _avisar('Debes declarar ser mayor de 18 años para registrarte.');
      return;
    }
    if (!_aceptoTerminos) {
      _avisar('Tenés que leer y aceptar los Términos y Condiciones.');
      return;
    }
    if (!_aceptoPrivacidad) {
      _avisar('Tenés que leer y aceptar la Política de Privacidad.');
      return;
    }
    if (_tokenVerificacion == null) {
      _avisar('Primero verificá tu número de celular.');
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
      aceptoPrivacidad: _aceptoPrivacidad,
      esMayorEdad: _esMayorEdad,
      tokenVerificacion: _tokenVerificacion!,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      _avisar(
        resultado['mensaje'] ??
            '¡Registro exitoso en Switch! Iniciá sesión para continuar.',
        exito: true,
      );
      Navigator.pop(context);
    } else {
      _avisar(resultado['mensaje'] ?? 'Error al registrar.');
    }
  }

  void _avisar(String mensaje, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: exito ? AppTheme.acentoVerdeEco : Colors.redAccent,
      ),
    );
  }

  String get _nombreCanal => _canalEnviado == 'WHATSAPP' ? 'WhatsApp' : 'SMS';

  // ==========================================
  // Interfaz
  // ==========================================

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
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _indicadorDePasos(theme),
                const SizedBox(height: 24),
                ..._contenidoDelPaso(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra en qué parte del registro está la persona usuaria.
  Widget _indicadorDePasos(ThemeData theme) {
    final pasos = ['Tus datos', 'Verificar', 'Términos'];
    final indiceActual = _paso.index;

    return Row(
      children: List.generate(pasos.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < indiceActual
                  ? AppTheme.acentoVerdeEco
                  : Colors.white12,
            ),
          );
        }
        final numero = i ~/ 2;
        final activo = numero <= indiceActual;
        return Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? AppTheme.acentoVerdeEco : Colors.white12,
          ),
          child: Text(
            '${numero + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: activo ? Colors.black : AppTheme.textoSecundario,
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _contenidoDelPaso(ThemeData theme) {
    switch (_paso) {
      case _Paso.datos:
        return _pasoDatos(theme);
      case _Paso.verificarCodigo:
        return _pasoCodigo(theme);
      case _Paso.aceptarTerminos:
        return _pasoTerminos(theme);
    }
  }

  // ---------- Paso 1: datos ----------
  List<Widget> _pasoDatos(ThemeData theme) {
    return [
      TextFormField(
        controller: _dniController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
            labelText: 'DNI (Sin puntos)',
            prefixIcon: Icon(Icons.badge_outlined),
            border: OutlineInputBorder()),
        style: theme.textTheme.bodyLarge,
        validator: (val) =>
            val == null || val.length < 7 ? 'Ingresá un DNI válido' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nombreController,
        decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder()),
        style: theme.textTheme.bodyLarge,
        validator: (val) =>
            val == null || val.isEmpty ? 'El nombre es obligatorio' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _apellidoController,
        decoration: const InputDecoration(
            labelText: 'Apellido',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder()),
        style: theme.textTheme.bodyLarge,
        validator: (val) =>
            val == null || val.isEmpty ? 'El apellido es obligatorio' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _telefonoController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
            labelText: 'Teléfono celular',
            helperText: 'Lo usamos sólo para verificar tu cuenta. '
                'Nunca se muestra a otros usuarios.',
            helperMaxLines: 2,
            prefixIcon: Icon(Icons.phone_android_outlined),
            border: OutlineInputBorder()),
        style: theme.textTheme.bodyLarge,
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return 'El teléfono es obligatorio';
          }
          if (val.replaceAll(RegExp(r'\D'), '').length < 8) {
            return 'Ingresá un número de celular válido';
          }
          return null;
        },
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
      const SizedBox(height: 12),
      CheckboxListTile(
        value: _esMayorEdad,
        onChanged: (val) => setState(() => _esMayorEdad = val ?? false),
        activeColor: AppTheme.acentoVerdeEco,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text('Declaro ser mayor de 18 años.',
            style: theme.textTheme.bodyLarge),
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _cargando
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  _pedirCodigo();
                }
              },
        child: _cargando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Text('VERIFICAR MI TELÉFONO'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _cargando
            ? null
            : () {
                _paso = _Paso.aceptarTerminos;
                setState(() {});
              },
        child: const Text(
          'Sólo quiero leer los Términos y la Política de Privacidad',
          style: TextStyle(fontSize: 12, color: AppTheme.textoSecundario),
        ),
      ),
    ];
  }

  // ---------- Paso 2: código ----------
  List<Widget> _pasoCodigo(ThemeData theme) {
    return [
      Icon(
        _canalEnviado == 'WHATSAPP' ? Icons.chat_outlined : Icons.sms_outlined,
        size: 48,
        color: AppTheme.acentoVerdeEco,
      ),
      const SizedBox(height: 16),
      Text(
        'Ingresá el código de 6 dígitos que te enviamos por $_nombreCanal',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 4),
      Text(
        'al ${_telefonoController.text.trim()}',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Vence en $_minutosValidez minutos. Tenés $_maxIntentos intentos.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
      if (_codigoMockVisible && _codigoMock != null) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.developer_mode, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Modo prueba: tu código es $_codigoMock',
                  style: const TextStyle(color: Colors.amber, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.amber, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _codigoMock!));
                  _avisar('Código copiado.', exito: true);
                },
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      Form(
        key: _formOtpKey,
        child: TextFormField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 26,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            hintText: '••••••',
            counterText: '',
            border: OutlineInputBorder(),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Ingresá el código que te enviamos';
            }
            if (val.trim().length != 6) {
              return 'El código tiene 6 dígitos';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _cargando ? null : _verificarCodigo,
        child: _cargando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Text('VERIFICAR CÓDIGO'),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _cargando || _segundosParaReenviar > 0
                ? null
                : () => _pedirCodigo(),
            child: Text(
              _segundosParaReenviar > 0
                  ? 'Reenviar en ${_segundosParaReenviar}s'
                  : 'Reenviar por $_nombreCanal',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _cargando
                ? null
                : () => _pedirCodigo(canalPreferido: 'WHATSAPP'),
            child: Text(
              _canalEnviado == 'WHATSAPP'
                  ? 'Enviar por SMS'
                  : 'Enviar por WhatsApp',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: _cargando ? null : _volverAEditarTelefono,
        child: const Text('Usar otro número',
            style: TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
      ),
    ];
  }

  // ---------- Paso 3: términos ----------
  List<Widget> _pasoTerminos(ThemeData theme) {
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.acentoVerdeEco.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.acentoVerdeEco.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user,
                color: AppTheme.acentoVerdeEco, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verificamos tu número por $_nombreCanal. Tu teléfono no se '
                'mostrará a nadie más.',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Leé los documentos y aceptalos para crear tu cuenta.',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 12),
      _tarjetaLegal(
        titulo: 'Términos y Condiciones',
        idDocumento: 'terminos',
        aceptado: _aceptoTerminos,
        onCambio: (valor) => setState(() => _aceptoTerminos = valor),
      ),
      const SizedBox(height: 12),
      _tarjetaLegal(
        titulo: 'Política de Privacidad',
        idDocumento: 'privacidad',
        aceptado: _aceptoPrivacidad,
        onCambio: (valor) => setState(() => _aceptoPrivacidad = valor),
      ),
      const SizedBox(height: 24),
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
      const SizedBox(height: 8),
      TextButton(
        onPressed: _cargando ? null : _volverAEditarTelefono,
        child: const Text('Volver',
            style: TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
      ),
    ];
  }

  /// Tarjeta con el nombre del documento, un botón para leerlo completo y
  /// el casillero de aceptación. La persona tiene que poder leer el texto
  /// sin obligarse a aceptarlo en el mismo gesto.
  Widget _tarjetaLegal({
    required String titulo,
    required String idDocumento,
    required bool aceptado,
    required Function(bool) onCambio,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.superficieTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: aceptado,
            activeColor: AppTheme.acentoVerdeEco,
            onChanged: (val) => onCambio(val ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Leo y acepto los $titulo',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => _abrirDocumento(idDocumento, titulo),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 16, color: AppTheme.acentoAzulTurquesa),
                        SizedBox(width: 6),
                        Text(
                          'Leer el texto completo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.acentoAzulTurquesa,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
