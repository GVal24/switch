import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio global de accesibilidad.
/// Todas las preferencias se persisten en el dispositivo y se aplican
/// en toda la app a través de los ValueNotifier (los escucha main.dart).
class AccesibilidadService {
  AccesibilidadService._();
  static final AccesibilidadService instancia = AccesibilidadService._();

  static const String _kEscalaTexto = 'acc_escala_texto';
  static const String _kAltoContraste = 'acc_alto_contraste';
  static const String _kPaletaSuave = 'acc_paleta_suave';
  static const String _kBlancoNegro = 'acc_blanco_negro';

  /// Escala del texto en toda la app (1.0 = normal, hasta 1.5)
  final ValueNotifier<double> escalaTexto = ValueNotifier<double>(1.0);

  /// Tema de alto contraste (negro/blanco/amarillo, bordes gruesos)
  final ValueNotifier<bool> altoContraste = ValueNotifier<bool>(false);

  /// Paleta suave y calma (pasteles de baja saturación)
  final ValueNotifier<bool> paletaSuave = ValueNotifier<bool>(false);

  /// Filtro de blanco y negro puro (elimina por completo los tonos de color)
  final ValueNotifier<bool> blancoNegro = ValueNotifier<bool>(false);

  bool _cargado = false;

  /// Carga las preferencias guardadas. Llamar una vez antes de runApp.
  Future<void> cargar() async {
    if (_cargado) return;
    final prefs = await SharedPreferences.getInstance();
    escalaTexto.value = prefs.getDouble(_kEscalaTexto) ?? 1.0;
    altoContraste.value = prefs.getBool(_kAltoContraste) ?? false;
    paletaSuave.value = prefs.getBool(_kPaletaSuave) ?? false;
    blancoNegro.value = prefs.getBool(_kBlancoNegro) ?? false;
    _cargado = true;
  }

  Future<void> _guardar(String clave, Object valor) async {
    final prefs = await SharedPreferences.getInstance();
    if (valor is double) {
      await prefs.setDouble(clave, valor);
    } else if (valor is bool) {
      await prefs.setBool(clave, valor);
    }
  }

  Future<void> setEscalaTexto(double valor) async {
    escalaTexto.value = valor.clamp(1.0, 1.5);
    await _guardar(_kEscalaTexto, escalaTexto.value);
  }

  Future<void> setAltoContraste(bool valor) async {
    altoContraste.value = valor;
    if (valor) paletaSuave.value = false; // son excluyentes entre sí
    await _guardar(_kAltoContraste, valor);
    await _guardar(_kPaletaSuave, paletaSuave.value);
  }

  Future<void> setPaletaSuave(bool valor) async {
    paletaSuave.value = valor;
    if (valor) altoContraste.value = false; // son excluyentes entre sí
    await _guardar(_kPaletaSuave, valor);
    await _guardar(_kAltoContraste, altoContraste.value);
  }

  Future<void> setBlancoNegro(bool valor) async {
    blancoNegro.value = valor;
    await _guardar(_kBlancoNegro, valor);
  }

  /// Restablece todas las preferencias a los valores originales
  Future<void> restablecerTodo() async {
    await setEscalaTexto(1.0);
    await setAltoContraste(false);
    await setPaletaSuave(false);
    await setBlancoNegro(false);
  }
}
