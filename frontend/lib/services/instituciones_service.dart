import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';
import 'geolocalizacion_service.dart';

class InstitucionesService {
  static final IGeolocalizacionService _geoService = GeolocalizacionService();

  static Future<List<dynamic>> obtenerInstituciones() async {
    try {
      final res =
          await http.get(Uri.parse('${ApiService.baseUrl}/instituciones'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['datos'] ?? decoded['instituciones'] ?? [];
        }
      }
    } catch (e) {
      print('Error en obtenerInstituciones: $e');
    }
    return [];
  }

  static Future<List<dynamic>> obtenerCuposPorInstitucion(
      String institucionId) async {
    try {
      final res = await http.get(Uri.parse(
          '${ApiService.baseUrl}/instituciones/$institucionId/cupos'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['datos'] ?? decoded['cupos'] ?? [];
        }
      }
    } catch (e) {
      print('Error en obtenerCuposPorInstitucion: $e');
    }
    return [];
  }

  /// Registro público de una institución con sus necesidades de voluntariado
  static Future<Map<String, dynamic>> registrarInstitucion({
    required String nombre,
    required String tipo,
    required String direccion,
    required String telefono,
    required String descripcion,
    required List<Map<String, dynamic>> necesidades,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/instituciones/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'tipo': tipo,
          'direccion': direccion,
          'telefono': telefono,
          'descripcion': descripcion,
          'necesidades': necesidades,
        }),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': (res.statusCode == 200 || res.statusCode == 201) &&
            decoded['exito'] == true,
        'mensaje': decoded['mensaje'] ?? 'No se pudo registrar la institución.',
      };
    } catch (e) {
      print('Error en registrarInstitucion: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> validarPresenciaQR({
    required String usuarioId,
    required String qrCodigoHash,
    double? latitud,
    double? longitud,
    String? cupoNecesidadId,
  }) async {
    try {
      // Si no vienen coordenadas de la UI, obtenemos las reales del GPS.
      // Si el GPS no está disponible se envían null y el backend omite
      // la validación de distancia (si está activada).
      double? lat = latitud;
      double? lng = longitud;

      if (lat == null || lng == null) {
        final ubicacion = await _geoService.obtenerUbicacionActual();
        lat = ubicacion?['latitud'];
        lng = ubicacion?['longitud'];
      }

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/validaciones/qr-scan'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({
          'qrCodigoHash': qrCodigoHash,
          'latitudUsuario': lat,
          'longitudUsuario': lng,
          'cupoNecesidadId': cupoNecesidadId,
        }),
      );

      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (decoded is Map<String, dynamic>) return decoded;
      } else {
        return {
          'exito': false,
          'mensaje':
              decoded['mensaje'] ?? 'Error al validar QR (${res.statusCode})'
        };
      }
    } catch (e) {
      print('Error en validarPresenciaQR: $e');
    }
    return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
  }
}
