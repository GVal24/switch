import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class ChatService {
  /// Motivo real del ultimo fallo devuelto por el backend (cuenta suspendida,
  /// usuario bloqueado, etc.) para poder informarlo en vez de mostrar un
  /// "intentá de nuevo" que hace creer que falló la conexión.
  static String? ultimoError;

  static String? _extraerMensaje(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['mensaje'] is String) {
        return decoded['mensaje'] as String;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> obtenerMensajes(
      String emisorId, String receptorId) async {
    ultimoError = null;
    try {
      // El emisor real lo determina el backend con el token; se envía solo el receptor
      final uri = Uri.parse('${ApiService.baseUrl}/mensajes').replace(
        queryParameters: {'receptorId': receptorId},
      );
      final res =
          await http.get(uri, headers: await AuthService.construirHeaders());
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['datos'] ?? decoded['mensajes'] ?? [];
        }
      }
      ultimoError =
          _extraerMensaje(res.body) ?? 'No se pudo abrir la conversación.';
    } catch (e) {
      ultimoError = 'No se pudo conectar con el servidor.';
    }
    return [];
  }

  static Future<bool> enviarMensaje({
    required String emisorId,
    required String receptorId,
    required String receptorNombre,
    required String texto,
  }) async {
    ultimoError = null;
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/mensajes/enviar'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({
          'receptorId': receptorId,
          'receptorNombre': receptorNombre,
          'texto': texto,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
      ultimoError =
          _extraerMensaje(res.body) ?? 'No se pudo enviar el mensaje.';
      return false;
    } catch (e) {
      ultimoError = 'No se pudo conectar con el servidor.';
      return false;
    }
  }
}
