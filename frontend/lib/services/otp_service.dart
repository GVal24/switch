import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Verificación del teléfono celular por código de un solo uso (OTP).
///
/// El flujo es en dos pasos:
///   1. pedirCodigo()      -> el backend envía el código por SMS o WhatsApp
///   2. verificarCodigo()  -> devuelve un comprobante que el registro exige
///
/// El comprobante es lo que permite crear la cuenta: sin él, el registro
/// se rechaza. Así nadie puede saltearse la verificación diciendo "ya la
/// hice".
class OtpService {
  /// Pide un código. `canalPreferido` puede ser 'SMS' o 'WHATSAPP';
  /// si no se indica, el backend usa su orden preferido (SMS primero).
  static Future<Map<String, dynamic>> pedirCodigo({
    required String telefono,
    String? canalPreferido,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/otp/solicitar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telefono': telefono,
          'proposito': 'REGISTRO',
          if (canalPreferido != null) 'canalPreferido': canalPreferido,
        }),
      );

      final decoded = _decodificar(res);

      if (res.statusCode == 200 && decoded['exito'] == true) {
        final datos =
            decoded['datos'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return {
          'exito': true,
          'mensaje':
              decoded['mensaje'] ?? 'Te enviamos un código de verificación.',
          'canalEnviado': datos['canalEnviado'],
          'minutosValidez': datos['minutosValidez'],
          'maxIntentos': datos['maxIntentos'],
          // Sólo viene en modo mock. Con un proveedor real no existe.
          'codigoMock': datos['codigoMock'],
          'esMock': datos['esMock'] == true,
          'segundosRestantes': decoded['detalles']?['segundosRestantes'],
        };
      }

      return {
        'exito': false,
        'mensaje': decoded['mensaje'] ?? 'No pudimos enviar el código.',
        'segundosRestantes': decoded['detalles']?['segundosRestantes'],
      };
    } catch (_) {
      return {
        'exito': false,
        'mensaje': 'Error de conexión con el servidor.',
      };
    }
  }

  /// Verifica el código. Si acierta, devuelve `tokenVerificacion`.
  static Future<Map<String, dynamic>> verificarCodigo({
    required String telefono,
    required String codigo,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/otp/verificar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telefono': telefono,
          'codigo': codigo,
          'proposito': 'REGISTRO',
        }),
      );

      final decoded = _decodificar(res);

      if (res.statusCode == 200 && decoded['exito'] == true) {
        final datos =
            decoded['datos'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return {
          'exito': true,
          'mensaje': decoded['mensaje'] ?? 'Teléfono verificado.',
          'tokenVerificacion': datos['tokenVerificacion'],
          'canalUtilizado': datos['canalUtilizado'],
        };
      }

      return {
        'exito': false,
        'mensaje': decoded['mensaje'] ?? 'El código no es válido.',
      };
    } catch (_) {
      return {
        'exito': false,
        'mensaje': 'Error de conexión con el servidor.',
      };
    }
  }

  static Map<String, dynamic> _decodificar(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) return body;
    } catch (_) {
      // cuerpo no JSON
    }
    return <String, dynamic>{};
  }
}
