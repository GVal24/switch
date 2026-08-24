import 'dart:math';

import 'package:geolocator/geolocator.dart';

abstract class IGeolocalizacionService {
  /// Devuelve latitud/longitud reales del teléfono.
  /// Devuelve null si el GPS está apagado o se denegaron los permisos,
  /// para que la validación de distancia se omita en el backend.
  Future<Map<String, double>?> obtenerUbicacionActual();

  bool verificarCercania({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    required double radioMaxMetros,
  });
}

class GeolocalizacionService implements IGeolocalizacionService {
  @override
  Future<Map<String, double>?> obtenerUbicacionActual() async {
    try {
      final bool servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) return null;

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      final Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return {'latitud': posicion.latitude, 'longitud': posicion.longitude};
    } catch (_) {
      // Cualquier fallo del GPS no debe bloquear la validación de presencia
      return null;
    }
  }

  @override
  bool verificarCercania({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    required double radioMaxMetros,
  }) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    final double distanciaMetros = 12742 * asin(sqrt(a)) * 1000;

    return distanciaMetros <= radioMaxMetros;
  }
}
