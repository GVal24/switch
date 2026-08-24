import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'catalogo_service.dart';
import 'instituciones_service.dart';
import 'chat_service.dart';
import 'admin_service.dart';
import 'geolocalizacion_service.dart';

class ApiService {
  // Configuración de red local
  static const String _ipComputadoraLocal = '192.168.0.162';
  static const String _puerto = '3000';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_puerto/api';
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 'http://$_ipComputadoraLocal:$_puerto/api';
    } else {
      return 'http://localhost:$_puerto/api';
    }
  }

  // ==========================================
  // 1. REGISTRO, LOGIN & SESIÓN (AuthService)
  // ==========================================
  static Future<Map<String, dynamic>> iniciarSesion({
    required String dni,
    required String password,
  }) =>
      AuthService.iniciarSesion(dni: dni, password: password);

  static Future<Map<String, dynamic>> registrarUsuario({
    required String dni,
    required String nombre,
    required String apellido,
    required String telefono,
    required String password,
    required bool aceptoTerminos,
    required bool esMayorEdad,
  }) =>
      AuthService.registrarUsuario(
        dni: dni,
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        password: password,
        aceptoTerminos: aceptoTerminos,
        esMayorEdad: esMayorEdad,
      );

  static Future<Map<String, dynamic>?> obtenerSesionGuardada() =>
      AuthService.obtenerSesionLocal();

  static Future<void> cerrarSesion() =>
      AuthService.cerrarSesion();

  // ==========================================
  // 2. CATÁLOGO & INTERCAMBIOS (CatalogoService)
  // ==========================================
  static Future<List<dynamic>> obtenerCatalogo({
    String? nivelEsfuerzo,
    String? busqueda,
    String? tipoItem,
  }) =>
      CatalogoService.obtenerCatalogo(
        nivelEsfuerzo: nivelEsfuerzo,
        busqueda: busqueda,
        tipoItem: tipoItem,
      );

  /// Publicaciones activas del usuario logueado (id tomado del token).
  static Future<List<dynamic>> obtenerMisPublicaciones() =>
      CatalogoService.obtenerMisPublicaciones();

  /// Sube una foto del dispositivo y devuelve {exito, url, mensaje}.
  static Future<Map<String, dynamic>> subirImagen(File archivo) =>
      CatalogoService.subirImagen(archivo);

  /// Nivel de esfuerzo que el servidor asignará a la publicación.
  static Future<String> clasificarEsfuerzo({
    required String titulo,
    required String descripcion,
    required String tipoItem,
  }) =>
      CatalogoService.clasificarEsfuerzo(
        titulo: titulo,
        descripcion: descripcion,
        tipoItem: tipoItem,
      );

  static Future<Map<String, dynamic>> crearPublicacion({
    required String titulo,
    required String descripcion,
    required String tipoItem,
    String? imagenUrl,
  }) =>
      CatalogoService.crearPublicacion(
        titulo: titulo,
        descripcion: descripcion,
        tipoItem: tipoItem,
        imagenUrl: imagenUrl,
      );

  /// Propone un trueque solo con publicaciones propias (validado en el servidor).
  static Future<Map<String, dynamic>> proponerSwitch({
    required String publicacionDeseadaId,
    required List<String> idsOfrecidos,
  }) =>
      CatalogoService.proponerSwitch(
        publicacionDeseadaId: publicacionDeseadaId,
        idsOfrecidos: idsOfrecidos,
      );

  /// Marca que el esfuerzo de una publicación está mal clasificado.
  static Future<Map<String, dynamic>> sugerirEsfuerzo({
    required String publicacionId,
    required String nivelSugerido,
  }) =>
      CatalogoService.sugerirEsfuerzo(
        publicacionId: publicacionId,
        nivelSugerido: nivelSugerido,
      );

  // ==========================================
  // 2b. MIS TRUEQUES (propuestas y confirmaciones)
  // ==========================================
  static Future<Map<String, dynamic>?> obtenerMisPropuestas() =>
      CatalogoService.obtenerMisPropuestas();

  static Future<Map<String, dynamic>> responderPropuesta(String intercambioId, String estado) =>
      CatalogoService.responderPropuesta(intercambioId, estado);

  static Future<Map<String, dynamic>> confirmarTrueque(
    String intercambioId, {
    int? puntaje,
    String? comentario,
  }) =>
      CatalogoService.confirmarTrueque(
        intercambioId,
        puntaje: puntaje,
        comentario: comentario,
      );

  // ==========================================
  // 2c. PERFIL CON ESTADÍSTICAS REALES
  // ==========================================
  static Future<Map<String, dynamic>?> obtenerMiPerfil() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/usuarios/perfil'),
        headers: await AuthService.construirHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['exito'] == true) {
          return decoded['datos'];
        }
      }
    } catch (e) {
      print('Error en obtenerMiPerfil: $e');
    }
    return null;
  }

  // ==========================================
  // 3. INSTITUCIONES & QR (InstitucionesService)
  // ==========================================
  static Future<List<dynamic>> obtenerInstituciones() =>
      InstitucionesService.obtenerInstituciones();

  static Future<List<dynamic>> obtenerCuposPorInstitucion(String institucionId) =>
      InstitucionesService.obtenerCuposPorInstitucion(institucionId);

  static Future<Map<String, dynamic>> registrarInstitucion({
    required String nombre,
    required String tipo,
    required String direccion,
    required String telefono,
    required String descripcion,
    required List<Map<String, dynamic>> necesidades,
  }) =>
      InstitucionesService.registrarInstitucion(
        nombre: nombre,
        tipo: tipo,
        direccion: direccion,
        telefono: telefono,
        descripcion: descripcion,
        necesidades: necesidades,
      );

  static Future<Map<String, dynamic>> validarPresenciaQR({
    required String usuarioId,
    required String qrCodigoHash,
    double? latitud,
    double? longitud,
    String? cupoNecesidadId,
  }) =>
      InstitucionesService.validarPresenciaQR(
        usuarioId: usuarioId,
        qrCodigoHash: qrCodigoHash,
        latitud: latitud,
        longitud: longitud,
        cupoNecesidadId: cupoNecesidadId,
      );

  // ==========================================
  // 4. CHAT / MENSAJERÍA (ChatService)
  // ==========================================
  static Future<List<dynamic>> obtenerMensajes(String emisorId, String receptorId) =>
      ChatService.obtenerMensajes(emisorId, receptorId);

  static Future<bool> enviarMensaje({
    required String emisorId,
    required String receptorId,
    required String receptorNombre,
    required String texto,
  }) =>
      ChatService.enviarMensaje(
        emisorId: emisorId,
        receptorId: receptorId,
        receptorNombre: receptorNombre,
        texto: texto,
      );

  // ==========================================
  // 5. ADMINISTRACIÓN & MODERACIÓN (AdminService)
  // ==========================================
  static Future<Map<String, dynamic>> obtenerEstadisticasAdmin() =>
      AdminService.obtenerEstadisticasAdmin();

  static Future<List<dynamic>> obtenerReportesAdmin() =>
      AdminService.obtenerReportesAdmin();

  static Future<bool> reportarUsuario({
    required String reportanteId,
    required String reportanteNombre,
    required String reportadoId,
    required String reportadoNombre,
    required String motivo,
  }) =>
      AdminService.reportarUsuario(
        reportanteId: reportanteId,
        reportanteNombre: reportanteNombre,
        reportadoId: reportadoId,
        reportadoNombre: reportadoNombre,
        motivo: motivo,
      );

  static Future<bool> darDeBajaUsuario(String usuarioId, String reporteId) =>
      AdminService.darDeBajaUsuario(usuarioId, reporteId);

  static Future<List<dynamic>> obtenerSugerenciasEsfuerzo() =>
      AdminService.obtenerSugerenciasEsfuerzo();

  static Future<Map<String, dynamic>> aplicarSugerenciaEsfuerzo(String sugerenciaId) =>
      AdminService.aplicarSugerenciaEsfuerzo(sugerenciaId);

  static Future<bool> descartarSugerenciaEsfuerzo(String sugerenciaId) =>
      AdminService.descartarSugerenciaEsfuerzo(sugerenciaId);

  // ==========================================
  // 6. GEOLOCALIZACIÓN (GeolocalizacionService)
  // ==========================================
  /// Ubicación real del teléfono. Null si el GPS está apagado
  /// o se denegaron los permisos.
  static Future<Map<String, double>?> obtenerUbicacionActual() =>
      GeolocalizacionService().obtenerUbicacionActual();
}