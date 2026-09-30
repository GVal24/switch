import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _sessionKey = 'usuario_sesion_activa';
  static const String _tokenKey = 'switch_token_jwt';

  // Almacenar usuario en almacenamiento local del dispositivo
  static Future<void> guardarSesionLocal(Map<String, dynamic> usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(usuario));
  }

  // Guardar / leer el token JWT de sesión
  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Headers estándar con el token de sesión (si existe)
  static Future<Map<String, String>> construirHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await obtenerToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Obtener sesión guardada localmente
  static Future<Map<String, dynamic>?> obtenerSesionLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usuarioJson = prefs.getString(_sessionKey);
    if (usuarioJson != null && usuarioJson.isNotEmpty) {
      try {
        return jsonDecode(usuarioJson) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Cerrar sesión local
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_tokenKey);
  }

  // ==========================================
  // LOGIN contra la API real (POST /auth/login)
  // ==========================================
  static Future<Map<String, dynamic>> iniciarSesion({
    required String dni,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dni': dni, 'password': password}),
      );

      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded['exito'] == true) {
        final datos = decoded['datos'] ?? {};

        final usuario = {
          'id': datos['id'].toString(),
          'dni': datos['dni'] ?? dni,
          'nombre': datos['nombre'] ?? '',
          'apellido': datos['apellido'] ?? '',
          'nombreCompleto': '${datos['nombre'] ?? ''} ${datos['apellido'] ?? ''}'.trim(),
          'telefono': datos['telefono'] ?? '',
          'rol': datos['rol'] ?? 'VECINO',
        };

        // Persistimos el token JWT para las próximas peticiones
        final token = datos['token'];
        if (token != null && token is String) {
          await guardarToken(token);
        }

        await guardarSesionLocal(usuario);
        return {'exito': true, 'mensaje': decoded['mensaje'], 'usuario': usuario};
      }

      return {
        'exito': false,
        'mensaje': decoded['mensaje'] ?? 'Credenciales incorrectas.',
      };
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  // Login exclusivo del panel admin: valida credenciales y guarda el token,
  // pero NO sobrescribe la sesión local del vecino activo.
  static Future<Map<String, dynamic>> iniciarSesionAdmin({
    required String dni,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dni': dni, 'password': password}),
      );

      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded['exito'] == true) {
        final datos = decoded['datos'] ?? {};

        final usuario = {
          'id': datos['id'].toString(),
          'dni': datos['dni'] ?? dni,
          'nombre': datos['nombre'] ?? '',
          'apellido': datos['apellido'] ?? '',
          'nombreCompleto': '${datos['nombre'] ?? ''} ${datos['apellido'] ?? ''}'.trim(),
          'telefono': datos['telefono'] ?? '',
          'rol': datos['rol'] ?? 'VECINO',
        };

        final token = datos['token'];
        if (token != null && token is String) {
          await guardarToken(token);
        }

        return {'exito': true, 'mensaje': decoded['mensaje'], 'usuario': usuario};
      }

      return {
        'exito': false,
        'mensaje': decoded['mensaje'] ?? 'Credenciales incorrectas.',
      };
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }

  // ==========================================
  // REGISTRO contra la API real (POST /auth/registro)
  // ==========================================
  static Future<Map<String, dynamic>> registrarUsuario({
    required String dni,
    required String nombre,
    required String apellido,
    required String telefono,
    required String password,
    required bool aceptoTerminos,
    required bool esMayorEdad,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dni': dni,
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telefono,
          'password': password,
          'aceptoTerminos': aceptoTerminos,
          'esMayorEdad': esMayorEdad,
        }),
      );

      final decoded = jsonDecode(res.body);

      if ((res.statusCode == 201 || res.statusCode == 200) && decoded['exito'] == true) {
        return {'exito': true, 'mensaje': decoded['mensaje'] ?? '¡Registro exitoso en Switch!'};
      }

      return {'exito': false, 'mensaje': decoded['mensaje'] ?? 'Error al registrar.'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión con el servidor.'};
    }
  }
}
