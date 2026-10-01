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

  static Future<bool> darDeBajaUsuario(
      String usuarioId, String reporteId) async {
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
  static Future<Map<String, dynamic>> suspenderUsuario(
      String usuarioId, int dias,
      {String? reporteId}) async {
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

  static Future<Map<String, dynamic>> aplicarSugerenciaEsfuerzo(
      String sugerenciaId) async {
    try {
      final res = await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/admin/sugerencias-esfuerzo/$sugerenciaId/aplicar'),
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
        Uri.parse(
            '${ApiService.baseUrl}/admin/sugerencias-esfuerzo/$sugerenciaId/descartar'),
        headers: await AuthService.construirHeaders(),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error en descartarSugerenciaEsfuerzo: $e');
      return false;
    }
  }

  // ==========================================
  // Moderación de publicaciones e imágenes
  // ==========================================

  /// Cola de revisión. Trae publicaciones con imagen (en cuarentena) y sin
  /// imagen (revisión de texto).
  static Future<List<dynamic>> obtenerColaModeracion() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/moderacion/pendientes'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['datos'] is Map) {
          final datos = decoded['datos'] as Map<String, dynamic>;
          return datos['pendientes'] as List<dynamic>? ?? [];
        }
      }
    } catch (e) {
      print('Error en obtenerColaModeracion: $e');
    }
    return [];
  }

  /// Números de la cola para el contador del panel.
  static Future<Map<String, dynamic>> obtenerEstadisticasModeracion() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/moderacion/estadisticas'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['datos'] is Map) {
          return decoded['datos'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error en obtenerEstadisticasModeracion: $e');
    }
    return {};
  }

  /// Baja el archivo de una imagen en cuarentena para poder mirarla.
  ///
  /// No se puede usar Image.network porque ese widget no manda el header de
  /// sesión: la imagen exige token de administrador, así que se piden los
  /// bytes con http y se muestran con Image.memory.
  static Future<List<int>?> descargarImagenModeracion(int moderacionId) async {
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/admin/moderacion/$moderacionId/imagen'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
      print('No se pudo descargar la imagen $moderacionId (${res.statusCode})');
    } catch (e) {
      print('Error en descargarImagenModeracion: $e');
    }
    return null;
  }

  /// Aprueba una publicación con imagen: pasa a estar visible en el catálogo.
  static Future<Map<String, dynamic>> aprobarModeracion(
      int moderacionId) async {
    return _postModeracion('/admin/moderacion/$moderacionId/aprobar', null);
  }

  /// Aprueba una publicación sin imagen (la revisión fue sobre el texto).
  static Future<Map<String, dynamic>> aprobarTexto(int publicacionId) async {
    return _postModeracion(
        '/admin/moderacion/texto/$publicacionId/aprobar', null);
  }

  /// Rechaza una publicación con imagen y borra el archivo del servidor.
  static Future<Map<String, dynamic>> rechazarModeracion(
    int moderacionId,
    String motivo,
  ) async {
    return _postModeracion(
      '/admin/moderacion/$moderacionId/rechazar',
      {'motivoRechazo': motivo},
    );
  }

  /// Rechaza una publicación sin imagen.
  static Future<Map<String, dynamic>> rechazarTexto(
    int publicacionId,
    String motivo,
  ) async {
    return _postModeracion(
      '/admin/moderacion/texto/$publicacionId/rechazar',
      {'motivoRechazo': motivo},
    );
  }

  /// Hallazgo de posible imagen de menor de edad (Ley 26.061).
  ///
  /// El archivo NO se borra: se conserva para remitirlo a la autoridad, y la
  /// cuenta de quien lo publicó queda suspendida. Por eso la confirmación pide
  /// verificar el motivo con cuidado.
  static Future<Map<String, dynamic>> marcarComoMenor(int moderacionId) async {
    return _postModeracion(
        '/admin/moderacion/$moderacionId/rechazar-menor', null);
  }

  static Future<Map<String, dynamic>> marcarTextoComoMenor(
      int publicacionId) async {
    return _postModeracion(
        '/admin/moderacion/texto/$publicacionId/rechazar-menor', null);
  }

  static Future<Map<String, dynamic>> _postModeracion(
    String ruta,
    Map<String, dynamic>? cuerpo,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}$ruta'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode(cuerpo ?? {}),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': res.statusCode == 200 && decoded['exito'] == true,
        'mensaje': decoded['mensaje'] ?? '',
        'datos': decoded['datos'],
      };
    } catch (e) {
      print('Error en $ruta: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }
}
