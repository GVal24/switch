import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Consulta los documentos legales desde la API.
///
/// No son textos fijos en la app: se piden al backend para que el usuario
/// vea siempre la misma versión que quedó registrada al aceptar. Así, si
/// el texto cambia, la app no queda mostrando un texto viejo.
class LegalService {
  /// Devuelve la lista de documentos disponibles con su versión y hash.
  static Future<List<dynamic>> listarDocumentos() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/legal'),
      );
      if (res.statusCode != 200) return <dynamic>[];

      final decoded = jsonDecode(res.body);
      final docs = decoded['datos']?['documentos'];
      return docs is List ? docs : <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  /// Devuelve el documento legal completo (con sus secciones).
  ///
  /// Si el backend no responde, devuelve un texto de respaldo que impide
  /// que alguien acepte una pantalla vacía sin enterarse.
  static Future<Map<String, dynamic>?> obtenerDocumento(String id) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/legal/$id'),
      );
      if (res.statusCode != 200) return null;

      final decoded = jsonDecode(res.body);
      return decoded['datos'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Convierte el documento recibido en un texto plano para mostrarlo.
  static String aTextoPlano(Map<String, dynamic> documento) {
    final buffer = StringBuffer();
    final titulo = documento['titulo'];
    if (titulo is String && titulo.isNotEmpty) {
      buffer.writeln(titulo);
      buffer.writeln();
    }

    final version = documento['version'];
    final vigenteDesde = documento['vigenteDesde'];
    if (version is String) {
      buffer.write('Versión $version');
      if (vigenteDesde is String && vigenteDesde.isNotEmpty) {
        buffer.write(' — vigente desde $vigenteDesde');
      }
      buffer.writeln();
      buffer.writeln();
    }

    final intro = documento['intro'];
    if (intro is String && intro.isNotEmpty) {
      buffer.writeln(intro);
      buffer.writeln();
    }

    final secciones = documento['secciones'];
    if (secciones is List) {
      for (final seccion in secciones) {
        if (seccion is! Map) continue;
        final tituloSeccion = seccion['titulo'];
        if (tituloSeccion is String && tituloSeccion.isNotEmpty) {
          buffer.writeln(tituloSeccion);
          buffer.writeln();
        }
        final cuerpo = seccion['cuerpo'];
        if (cuerpo is List) {
          for (final parrafo in cuerpo) {
            if (parrafo is String && parrafo.isNotEmpty) {
              buffer.writeln(parrafo);
              buffer.writeln();
            }
          }
        }
      }
    }

    return buffer.toString().trim();
  }
}
