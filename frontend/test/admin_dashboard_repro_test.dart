import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/screens/admin_dashboard_screen.dart';
import 'package:frontend/services/accesibilidad_service.dart';
import 'package:frontend/theme/app_theme.dart';

/// Respuestas JSON exactas (mismas estructura que el backend real).
const estadisticasJson = '''
{"usuariosActivos":12,"truequesMes":4,"voluntariadosQr":15,"reportesPendientes":6,
 "tasaEfectividad":"75%","meses":["Apr","May","Jun","Jul","Aug","Sep"],
 "actividadMensual":[3,4,4,4,9,4],
 "esfuerzoDistribucion":{"SIMPLE":38.5,"ALTO":38.5,"MEDIO":23.1}}
''';

const reportesJson = '''
{"exito":true,"reportes":[
 {"id":8,"reportante_id":"12","reportante_nombre":"Vecino Doce","reportado_id":"9","reportado_nombre":"Vecino Nueve","motivo":"mensaje ofensivo","estado":"PENDIENTE","creado_en":"04/09/2026 08:24"},
 {"id":7,"reportante_id":"11","reportante_nombre":"Vecino Once","reportado_id":"2","reportado_nombre":"Vecino Dos","motivo":"estafa","estado":"PENDIENTE","creado_en":"03/09/2026 18:02"},
 {"id":6,"reportante_id":"10","reportante_nombre":"Vecino Diez","reportado_id":"5","reportado_nombre":"Vecino Cinco","motivo":"no se presento","estado":"PENDIENTE","creado_en":"02/09/2026 09:40"},
 {"id":5,"reportante_id":"9","reportante_nombre":"Vecino Nueve","reportado_id":"3","reportado_nombre":"Vecino Tres","motivo":"mal trato","estado":"PENDIENTE","creado_en":"01/09/2026 21:15"},
 {"id":4,"reportante_id":"8","reportante_nombre":"Vecino Ocho","reportado_id":"0","reportado_nombre":"","motivo":"publicacion duplicada","estado":"RESUELTO","creado_en":"01/09/2026 11:00"},
 {"id":3,"reportante_id":"7","reportante_nombre":"Vecino Siete","reportado_id":"2","reportado_nombre":"Vecino Dos","motivo":"demora","estado":"DESESTIMADO","creado_en":"31/08/2026 16:30"},
 {"id":2,"reportante_id":"5","reportante_nombre":"Vecino Cinco","reportado_id":"1","reportado_nombre":"Vecino Uno","motivo":"objeto roto","estado":"PENDIENTE","creado_en":"31/08/2026 10:12"},
 {"id":1,"reportante_id":"4","reportante_nombre":"Vecino Cuatro","reportado_id":"0","reportado_nombre":"","motivo":"reclamo general","estado":"PENDIENTE","creado_en":"30/08/2026 08:00"}
]}
''';

const sugerenciasJson = '''
{"exito":true,"datos":[
 {"id":1,"publicacion_id":3,"publicacion_titulo":"Bicicleta de 26 para canje","nivel_actual":"SIMPLE","nivel_sugerido":"ALTO","sugerido_por":"Vecino Uno","creado_en":"04/09/2026 08:00"},
 {"id":2,"publicacion_id":7,"publicacion_titulo":"Clases de ingles nivel basico","nivel_actual":"MEDIO","nivel_sugerido":"ALTO","sugerido_por":"Vecino Dos","creado_en":"03/09/2026 19:30"},
 {"id":3,"publicacion_id":9,"publicacion_titulo":"Ayuda con mudanza","nivel_actual":"ALTO","nivel_sugerido":"MEDIO","sugerido_por":"Vecino Tres","creado_en":"02/09/2026 13:10"},
 {"id":4,"publicacion_id":11,"publicacion_titulo":"Plantines de aromatica","nivel_actual":"ALTO","nivel_sugerido":"SIMPLE","sugerido_por":"Vecino Cuatro","creado_en":"01/09/2026 09:00"},
 {"id":5,"publicacion_id":13,"publicacion_titulo":"Reparacion de PC basica","nivel_actual":"SIMPLE","nivel_sugerido":"MEDIO","sugerido_por":"Vecino Cinco","creado_en":"01/09/2026 07:45"}
]}
''';

/// Fake HttpClient que responde 200 con los JSON de los endpoints admin.
class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeRequest(url);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _FakeRequest(url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      _FakeRequestWithHost(host, port, path);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async =>
      _FakeRequestWithHost(host, port, path);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) async =>
      _FakeRequestWithHost(host, port, path);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async =>
      _FakeRequestWithHost(host, port, path);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Método no soportado en FakeHttpClient');
  }
}

class _FakeRequest implements HttpClientRequest {
  final Uri url;
  _FakeRequest(this.url);

  final List<int> _body = [];

  @override
  Future<HttpClientResponse> close() async {
    return _FakeResponse(_respuestaPara(url));
  }

  List<int> _respuestaPara(Uri url) {
    final path = url.path;
    if (path.endsWith('/admin/estadisticas')) {
      return _utf8(estadisticasJson);
    }
    if (path.endsWith('/admin/reportes')) {
      return _utf8(reportesJson);
    }
    if (path.endsWith('/admin/sugerencias-esfuerzo')) {
      return _utf8(sugerenciasJson);
    }
    return _utf8('{"error":"not found"}');
  }

  static List<int> _utf8(String s) => s.codeUnits;

  @override
  HttpHeaders get headers => _FakeHeaders();

  @override
  String get method => 'GET';

  @override
  Uri get uri => url;

  @override
  void add(List<int> data) => _body.addAll(data);

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final d in stream) {
      _body.addAll(d);
    }
  }

  @override
  void write(Object? object) => _body.addAll(object.toString().codeUnits);

  @override
  void writeln([Object? object = '']) => _body.addAll('$object\n'.codeUnits);

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    for (final o in objects) {
      _body.addAll(o.toString().codeUnits);
      _body.addAll(separator.codeUnits);
    }
  }

  @override
  void writeCharCode(int charCode) => _body.add(charCode);

  @override
  Future<HttpClientResponse> get done => Future.value(_FakeResponse(_body));

  @override
  bool get followRedirects => true;

  @override
  set followRedirects(bool value) {}

  @override
  int get maxRedirects => 5;

  @override
  set maxRedirects(int value) {}

  @override
  bool get persistentConnection => true;

  @override
  set persistentConnection(bool value) {}

  @override
  int get contentLength => _body.length;

  @override
  set contentLength(int value) {}

  @override
  bool get bufferOutput => false;

  @override
  set bufferOutput(bool value) {}

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  Future<void> flush() async {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
        'Método no soportado en FakeRequest: ${invocation.memberName}');
  }
}

class _FakeRequestWithHost implements HttpClientRequest {
  _FakeRequestWithHost(String host, int port, String path)
      : uri = Uri.parse('http://$host:$port$path');

  @override
  final Uri uri;
  final List<int> _body = [];

  @override
  Future<HttpClientResponse> close() async {
    return _FakeResponse(_body.isEmpty ? _jsonPendiente() : _body);
  }

  List<int> _jsonPendiente() => '{"exito":false}'.codeUnits;

  @override
  HttpHeaders get headers => _FakeHeaders();

  @override
  void add(List<int> data) => _body.addAll(data);

  @override
  void write(Object? object) => _body.addAll(object.toString().codeUnits);

  @override
  void writeln([Object? object = '']) => _body.addAll('$object\n'.codeUnits);

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    for (final o in objects) {
      _body.addAll(o.toString().codeUnits);
      _body.addAll(separator.codeUnits);
    }
  }

  @override
  void writeCharCode(int charCode) => _body.add(charCode);

  @override
  bool get followRedirects => true;

  @override
  set followRedirects(bool value) {}

  @override
  int get maxRedirects => 5;

  @override
  set maxRedirects(int value) {}

  @override
  bool get persistentConnection => true;

  @override
  set persistentConnection(bool value) {}

  @override
  int get contentLength => _body.length;

  @override
  set contentLength(int value) {}

  @override
  bool get bufferOutput => false;

  @override
  set bufferOutput(bool value) {}

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  Future<void> flush() async {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  Future<HttpClientResponse> get done => Future.value(_FakeResponse(_body));

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Método no soportado en FakeRequestWithHost');
  }
}

class _FakeHeaders implements HttpHeaders {
  final List<MapEntry<String, String>> _entries = [];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _entries.add(MapEntry(name, value.toString()));
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _entries.removeWhere((e) => e.key.toLowerCase() == name.toLowerCase());
    add(name, value);
  }

  @override
  String? value(String name) {
    for (final e in _entries) {
      if (e.key.toLowerCase() == name.toLowerCase()) return e.value;
    }
    return null;
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    final grouped = <String, List<String>>{};
    for (final e in _entries) {
      grouped.putIfAbsent(e.key.toLowerCase(), () => []).add(e.value);
    }
    grouped.forEach((name, values) => action(name, values));
  }

  @override
  List<String>? operator [](String name) {
    final v = value(name);
    return v == null ? null : [v];
  }

  @override
  void remove(String name, Object value) {
    _entries.removeWhere((e) =>
        e.key.toLowerCase() == name.toLowerCase() &&
        e.value == value.toString());
  }

  @override
  void removeAll(String name) {
    _entries.removeWhere((e) => e.key.toLowerCase() == name.toLowerCase());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
        'Método no soportado en FakeHeaders: ${invocation.memberName}');
  }
}

class _FakeResponse implements HttpClientResponse {
  final List<int> _data;
  _FakeResponse(this._data);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _data.length;

  @override
  HttpHeaders get headers => _FakeHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  String get reasonPhrase => 'OK';

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_data]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<String> fold<String>(String initialValue,
      String combine(String previous, Uint8List element)) async {
    return combine(initialValue, Uint8List.fromList(_data));
  }

  @override
  Future<E> drain<E>([E? futureValue]) async {
    return futureValue!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Método no soportado en FakeResponse');
  }
}

void main() {
  testWidgets('AdminDashboardScreen con datos reales no lanza "infinite width"',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AccesibilidadService.instancia.cargar();
    await tester.binding.setSurfaceSize(const Size(412, 915));

    // Mock HTTP global para que AdminService reciba los datos reales
    HttpOverrides.global = _FakeHttpOverrides();

    final List<String> errores = [];
    final handlerOriginal = FlutterError.onError;
    FlutterError.onError = (detalles) {
      errores.add(detalles.exceptionAsString());
      handlerOriginal?.call(detalles);
    };

    await tester.pumpWidget(MaterialApp(
      home: AdminDashboardScreen(onCerrarSesion: () {}),
    ));

    // Espera a que terminen las 3 llamadas HTTP simuladas
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verifica que se renderizaron secciones con datos
    expect(find.textContaining('Métricas de la Red'), findsOneWidget);
    expect(find.textContaining('Denuncias y Reportes'), findsOneWidget);

    FlutterError.onError = handlerOriginal;

    for (var e in errores) {
      debugPrint('ERROR PANEL: $e');
    }
    expect(
      errores.where((e) =>
          e.contains('infinite width') || e.contains('BoxConstraints forces')),
      isEmpty,
      reason: 'Se reprodujo "BoxConstraints forces an infinite width":\n'
          '${errores.take(5).join('\n---\n')}',
    );
  });

  // Regresión del crash del dispositivo real (384 dp de ancho lógico).
  //
  // AppTheme define `minimumSize: const Size(double.infinity, N)` en sus cuatro
  // temas para que los botones ocupen todo el ancho. Ese truco solo es válido
  // cuando el padre impone un ancho acotado: dentro de un `Row` o un `Wrap` el
  // hijo no flexible recibe `maxWidth: Infinity`, el `minWidth: Infinity` del
  // tema se propaga al `PhysicalShape` del botón y Flutter lanza
  // "BoxConstraints forces an infinite width", dejando el panel en blanco
  // (admin_dashboard_screen.dart:430, :440 y :546).
  final Map<String, ThemeData> temas = <String, ThemeData>{
    'temaEstandar': AppTheme.temaEstandar,
    'temaVistaAccesible': AppTheme.temaVistaAccesible,
    'temaAltoContraste': AppTheme.temaAltoContraste,
    'temaPaletaSuave': AppTheme.temaPaletaSuave,
  };

  temas.forEach((String nombreTema, ThemeData tema) {
    for (final double escala in <double>[1.0, 1.5]) {
      testWidgets(
          'Panel admin a 384dp sin ancho infinito ($nombreTema, escala $escala)',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        AccesibilidadService.instancia.escalaTexto.value = escala;
        await tester.binding.setSurfaceSize(const Size(384, 808));

        HttpOverrides.global = _FakeHttpOverrides();

        final List<String> errores = [];
        final handlerOriginal = FlutterError.onError;
        FlutterError.onError = (detalles) {
          errores.add(detalles.exceptionAsString());
          handlerOriginal?.call(detalles);
        };
        addTearDown(() {
          FlutterError.onError = handlerOriginal;
          HttpOverrides.global = null;
        });

        await tester.pumpWidget(MaterialApp(
          theme: tema,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(escala)),
            child: child!,
          ),
          home: AdminDashboardScreen(
              onCerrarSesion: () {}, modoAccesibleActivo: true),
        ));

        await tester.pump(const Duration(seconds: 1));
        // Pumps acotados (no pumpAndSettle): si el layout revienta, el panel
        // queda en un bucle de relayout y pumpAndSettle nunca converge.
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }

        // El panel debe llegar a pintarse con datos reales.
        expect(find.textContaining('Denuncias y Reportes'), findsOneWidget);
        expect(
          errores.where((e) =>
              e.contains('infinite width') ||
              e.contains('BoxConstraints forces')),
          isEmpty,
          reason:
              'Se reprodujo "BoxConstraints forces an infinite width" con $nombreTema '
              '(escala $escala):\n${errores.take(5).join('\n---\n')}',
        );
      });
    }
  });
}
