import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class ChatService {
  static Future<List<dynamic>> obtenerMensajes(String emisorId, String receptorId) async {
    try {
      // El emisor real lo determina el backend con el token; se envía solo el receptor
      final uri = Uri.parse('${ApiService.baseUrl}/mensajes').replace(
        queryParameters: {'receptorId': receptorId},
      );
      final res = await http.get(uri, headers: await AuthService.construirHeaders());
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['datos'] ?? decoded['mensajes'] ?? [];
        }
      }
    } catch (e) {
      print('Error al obtener mensajes: $e');
    }
    return [];
  }

  static Future<bool> enviarMensaje({
    required String emisorId,
    required String receptorId,
    required String receptorNombre,
    required String texto,
  }) async {
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
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Error al enviar mensaje: $e');
      return false;
    }
  }
}
