import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class AdminService {
  static Future<Map<String, dynamic>> obtenerEstadisticasAdmin() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/estadisticas'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (e) {
      print('Error en obtenerEstadisticasAdmin: $e');
    }
    return {};
  }

  static Future<List<dynamic>> obtenerReportesAdmin() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/reportes'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['datos'] ?? decoded['reportes'] ?? [];
        }
      }
    } catch (e) {
      print('Error en obtenerReportesAdmin: $e');
    }
    return [];
  }

  static Future<bool> reportarUsuario({
    required String reportanteId,
    required String reportanteNombre,
    required String reportadoId,
    required String reportadoNombre,
    required String motivo,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/reportes'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({
          'reportadoId': reportadoId,
          'reportadoNombre': reportadoNombre,
          'motivo': motivo,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Error en reportarUsuario: $e');
      return false;
    }
  }

  static Future<bool> darDeBajaUsuario(String usuarioId, String reporteId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/dar-de-baja'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({
          'usuarioId': usuarioId,
          'reporteId': reporteId,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error en darDeBajaUsuario: $e');
      return false;
    }
  }

  /// Suspende a un usuario por N días. Con dias = 0 levanta la suspensión.
  static Future<Map<String, dynamic>> suspenderUsuario(String usuarioId, int dias, {String? reporteId}) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/suspender'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({
          'usuarioId': usuarioId,
          'dias': dias,
          if (reporteId != null && reporteId.isNotEmpty) 'reporteId': reporteId,
        }),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': res.statusCode == 200 && decoded['exito'] == true,
        'mensaje': decoded['mensaje'],
      };
    } catch (e) {
      print('Error en suspenderUsuario: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  static Future<bool> desestimarReporte(String reporteId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/reportes/$reporteId/desestimar'),
        headers: await AuthService.construirHeaders(),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error en desestimarReporte: $e');
      return false;
    }
  }

  // ==========================================
  // Sugerencias de nivel de esfuerzo
  // ==========================================
  static Future<List<dynamic>> obtenerSugerenciasEsfuerzo() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/sugerencias-esfuerzo'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) return decoded;
        if (decoded is Map) return decoded['datos'] ?? [];
      }
    } catch (e) {
      print('Error en obtenerSugerenciasEsfuerzo: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> aplicarSugerenciaEsfuerzo(String sugerenciaId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/sugerencias-esfuerzo/$sugerenciaId/aplicar'),
        headers: await AuthService.construirHeaders(),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': res.statusCode == 200 && decoded['exito'] == true,
        'mensaje': decoded['mensaje'] ?? '',
      };
    } catch (e) {
      print('Error en aplicarSugerenciaEsfuerzo: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  static Future<bool> descartarSugerenciaEsfuerzo(String sugerenciaId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/sugerencias-esfuerzo/$sugerenciaId/descartar'),
        headers: await AuthService.construirHeaders(),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error en descartarSugerenciaEsfuerzo: $e');
      return false;
    }
  }
}
