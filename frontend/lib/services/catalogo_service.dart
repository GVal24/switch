import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class CatalogoService {
  static Future<List<dynamic>> obtenerCatalogo({
    String? nivelEsfuerzo,
    String? busqueda,
    String? tipoItem,
  }) async {
    try {
      final params = <String, String>{};
      if (nivelEsfuerzo != null && nivelEsfuerzo.isNotEmpty) {
        params['nivelEsfuerzo'] = nivelEsfuerzo;
      }
      if (busqueda != null && busqueda.trim().isNotEmpty) {
        params['busqueda'] = busqueda.trim();
      }
      if (tipoItem != null && tipoItem.isNotEmpty && tipoItem != 'TODOS') {
        params['tipoItem'] = tipoItem;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/catalogo').replace(
        queryParameters: params.isNotEmpty ? params : null,
      );
      final res = await http.get(uri, headers: await AuthService.construirHeaders());
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded['datos'] ?? decoded['catalogo'] ?? decoded['publicaciones'] ?? [];
        }
      }
    } catch (e) {
      print('Error en obtenerCatalogo: $e');
    }
    return [];
  }

  /// Publicaciones activas del usuario logueado (el id viene del token).
  static Future<List<dynamic>> obtenerMisPublicaciones() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/catalogo/mis-publicaciones'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['exito'] == true) {
          return decoded['datos'] ?? [];
        }
        if (decoded is List) return decoded;
      }
    } catch (e) {
      print('Error en obtenerMisPublicaciones: $e');
    }
    return [];
  }

  /// Sube una foto elegida del dispositivo y devuelve {exito, url, mensaje}.
  static Future<Map<String, dynamic>> subirImagen(File archivo) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/catalogo/imagen'),
      );
      request.headers.addAll(await AuthService.construirHeaders());
      request.files.add(
        await http.MultipartFile.fromPath('imagen', archivo.path),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(res.body);

      return {
        'exito': (res.statusCode == 201 || res.statusCode == 200) && decoded['exito'] == true,
        'url': decoded['datos']?['url'],
        'mensaje': decoded['mensaje'] ?? 'No se pudo subir la imagen.',
      };
    } catch (e) {
      print('Error en subirImagen: $e');
      return {'exito': false, 'url': null, 'mensaje': 'Error de conexión al subir la imagen.'};
    }
  }

  /// Pide al servidor el nivel de esfuerzo que se le asignará a la publicación.
  static Future<String> clasificarEsfuerzo({
    required String titulo,
    required String descripcion,
    required String tipoItem,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/catalogo/clasificar-esfuerzo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titulo': titulo,
          'descripcion': descripcion,
          'tipoItem': tipoItem,
        }),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['datos']?['nivelEsfuerzo'] ?? 'SIMPLE';
      }
    } catch (e) {
      print('Error en clasificarEsfuerzo: $e');
    }
    return 'SIMPLE';
  }

  static Future<Map<String, dynamic>> crearPublicacion({
    required String titulo,
    required String descripcion,
    required String tipoItem,
    String? imagenUrl,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/catalogo/publicar'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({
          'titulo': titulo,
          'descripcion': descripcion,
          'tipoItem': tipoItem,
          if (imagenUrl != null && imagenUrl.isNotEmpty) 'imagenUrl': imagenUrl,
        }),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': res.statusCode == 201 || res.statusCode == 200,
        'mensaje': decoded['mensaje'] ?? '',
      };
    } catch (e) {
      print('Error en crearPublicacion: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  /// Propone un trueque ofreciendo publicaciones propias (por id).
  /// El servidor valida que cada ítem sea una publicación activa propia.
  static Future<Map<String, dynamic>> proponerSwitch({
    required String publicacionDeseadaId,
    required List<String> idsOfrecidos,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/intercambios/proponer'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({
          'publicacionDeseadaId': publicacionDeseadaId,
          'itemsOfrecidos': idsOfrecidos,
        }),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': res.statusCode == 200 || res.statusCode == 201,
        'mensaje': decoded['mensaje'] ?? 'No se pudo enviar la propuesta.',
      };
    } catch (e) {
      print('Error en proponerSwitch: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  /// Marca que el nivel de esfuerzo de una publicación está mal clasificado.
  static Future<Map<String, dynamic>> sugerirEsfuerzo({
    required String publicacionId,
    required String nivelSugerido,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/catalogo/$publicacionId/sugerir-esfuerzo'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({'nivelSugerido': nivelSugerido}),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': (res.statusCode == 200 || res.statusCode == 201) && decoded['exito'] == true,
        'mensaje': decoded['mensaje'] ?? 'No se pudo enviar la sugerencia.',
      };
    } catch (e) {
      print('Error en sugerirEsfuerzo: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  // ==========================================
  // Ciclo de vida del trueque (Mis Trueques)
  // ==========================================
  static Future<Map<String, dynamic>?> obtenerMisPropuestas() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/intercambios/mis-propuestas'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['exito'] == true) {
          return decoded['datos'] ?? {};
        }
      }
    } catch (e) {
      print('Error en obtenerMisPropuestas: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> responderPropuesta(String intercambioId, String estado) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/intercambios/$intercambioId/responder'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode({'estado': estado}),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': res.statusCode == 200 && decoded['exito'] == true,
        'mensaje': decoded['mensaje'] ?? 'No se pudo responder la propuesta.',
      };
    } catch (e) {
      print('Error en responderPropuesta: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> confirmarTrueque(
    String intercambioId, {
    int? puntaje,
    String? comentario,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (puntaje != null) body['puntaje'] = puntaje;
      if (comentario != null && comentario.trim().isNotEmpty) body['comentario'] = comentario.trim();

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/intercambios/$intercambioId/confirmar'),
        headers: await AuthService.construirHeaders(),
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(res.body);
      return {
        'exito': res.statusCode == 200 && decoded['exito'] == true,
        'mensaje': decoded['mensaje'] ?? 'No se pudo confirmar el trueque.',
      };
    } catch (e) {
      print('Error en confirmarTrueque: $e');
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }
}
