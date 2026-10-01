import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

/// Canal para que cualquier persona le escriba a la administración.
///
/// Se usa con o sin sesión a propósito: una persona a la que acaban de
/// bloquearle la cuenta igual puede necesitar preguntar algo, y ahí no hay
/// token válido. El backend acepta las dos formas.
class ContactoService {
  /// Los tres motivos que se ofrecen. El backend rechaza cualquier otro.
  static const List<String> asuntos = ['PREGUNTA', 'COMENTARIO', 'CONTACTO'];

  static String etiquetaAsunto(String asunto) {
    switch (asunto) {
      case 'PREGUNTA':
        return 'Pregunta';
      case 'COMENTARIO':
        return 'Comentario';
      case 'CONTACTO':
        return 'Contacto';
      default:
        return 'Consulta';
    }
  }

  /// Envía un mensaje. Devuelve el texto de error si no se pudo enviar.
  static Future<String?> enviar({
    required String asunto,
    required String mensaje,
    String? nombre,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/contacto'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({
          'asunto': asunto,
          'mensaje': mensaje,
          if (nombre != null && nombre.isNotEmpty) 'nombre': nombre,
        }),
      );

      final decoded = jsonDecode(res.body);
      if (res.statusCode == 201 && decoded is Map && decoded['exito'] == true) {
        return null;
      }
      if (decoded is Map && decoded['mensaje'] is String) {
        return decoded['mensaje'] as String;
      }
      return 'No se pudo enviar el mensaje.';
    } catch (e) {
      print('Error en ContactoService.enviar: $e');
      return 'No pudimos escribir en el servidor. Revisá tu conexión.';
    }
  }
}
