import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/services/accesibilidad_service.dart';

const _estadisticasJson = '''
{"usuariosActivos":12,"truequesMes":4,"voluntariadosQr":15,"reportesPendientes":6,
 "tasaEfectividad":"75%","meses":["Apr","May","Jun","Jul","Aug","Sep"],
 "actividadMensual":[3,4,4,4,9,4],
 "esfuerzoDistribucion":{"SIMPLE":38.5,"ALTO":38.5,"MEDIO":23.1}}
''';

const _institucionesJson = '''
{"exito":true,"instituciones":[
 {"id":1,"nombre":"Centro de Salud Barrial","descripcion":"Atención primaria de salud","direccion":"Calle 1 234","contacto":"4444-1111","horarios":"Lun a Vie 8-18"},
 {"id":2,"nombre":"Biblioteca Municipal","descripcion":"Espacio de lectura y computación","direccion":"Av. 2 567","contacto":"4444-2222","horarios":"Lun a Vie 9-20"},
 {"id":3,"nombre":"Club Deportivo El Vecino","descripcion":"Talleres y actividades deportivas","direccion":"Calle 3 890","contacto":"4444-3333","horarios":"Lun a Dom 9-22"}
]}
''';

const _publicacionesJson = '''
{"exito":true,"publicaciones":[
 {"id":1,"titulo":"Bicicleta de 26 para canje","descripcion":"Rueda perfecta, sin detalles","tipo":"OBJETO","categoria_id":2,"esfuerzo":"SIMPLE","publi_estado":"DISPONIBLE","usuario_publi_id":1,"usuario_publi_nombre":"Vecino Uno","fecha":"01/09/2026"},
 {"id":2,"titulo":"Clases de ingles nivel basico","descripcion":"Dos encuentros por semana","tipo":"SERVICIO","categoria_id":5,"esfuerzo":"MEDIO","publi_estado":"DISPONIBLE","usuario_publi_id":2,"usuario_publi_nombre":"Vecino Dos","fecha":"01/09/2026"}
]}
''';

const _perfilVecinoJson = '''
{"exito":true,"usuario":{"id":"1","nombreCompleto":"Vecino Uno","dni":"11111112","rol":"VECINO"},"estadisticas":{},"publicaciones_activas":[],"impacto":{}}
''';

class _FakeOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeClient();
}

class _FakeClient implements HttpClient {
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
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeRequest(url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      _FakeRequest(Uri.parse('http://$host:$port$path'));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async =>
      _FakeRequest(Uri.parse('http://$host:$port$path'), metodo: 'POST');

  @override
  Future<HttpClientRequest> put(String host, int port, String path) async =>
      _FakeRequest(Uri.parse('http://$host:$port$path'), metodo: 'PUT');

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async =>
      _FakeRequest(Uri.parse('http://$host:$port$path'), metodo: 'DELETE');

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeClient: ${invocation.memberName}');
}

class _FakeRequest implements HttpClientRequest {
  final Uri url;
  final String metodo;
  _FakeRequest(this.url, {this.metodo = 'GET'});

  final List<int> _body = [];

  @override
  HttpHeaders get headers => _FakeHeaders();
  @override
  String get method => metodo;
  @override
  Uri get uri => url;
  @override
  bool get followRedirects => true;
  @override
  set followRedirects(bool v) {}
  @override
  int get maxRedirects => 5;
  @override
  set maxRedirects(int v) {}
  @override
  bool get persistentConnection => true;
  @override
  set persistentConnection(bool v) {}
  @override
  int get contentLength => _body.length;
  @override
  set contentLength(int v) {}
  @override
  bool get bufferOutput => false;
  @override
  set bufferOutput(bool v) {}
  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding v) {}

  @override
  void add(List<int> data) => _body.addAll(data);

  @override
  Future<void> addStream(Stream<List<int>> s) async {
    await for (final d in s) {
      _body.addAll(d);
    }
  }

  @override
  void write(Object? o) => _body.addAll(o.toString().codeUnits);
  @override
  void writeln([Object? o = '']) => _body.addAll('$o\n'.codeUnits);
  @override
  void writeAll(Iterable objects, [String separator = '']) {
    for (final o in objects) {
      _body.addAll(o.toString().codeUnits);
      _body.addAll(separator.codeUnits);
    }
  }

  @override
  void writeCharCode(int c) => _body.add(c);
  @override
  Future<void> flush() async {}
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(_respuesta(url));

  static List<int> _respuesta(Uri url) {
    final path = url.path;
    final body = path.contains('/admin/estadisticas')
        ? _estadisticasJson
        : path.contains('/admin/reportes')
            ? _reportesJson
            : path.contains('/admin/sugerencias-esfuerzo')
                ? _sugerenciasJson
                : path.contains('/instituciones')
                    ? _institucionesJson
                    : path.contains('/publicaciones')
                        ? _publicacionesJson
                        : _perfilVecinoJson;
    return body.codeUnits;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeRequest: ${invocation.memberName}');
}

const _reportesJson = '{"exito":true,"reportes":[]}';
const _sugerenciasJson = '{"exito":true,"datos":[]}';

class _FakeHeaders implements HttpHeaders {
  final List<MapEntry<String, String>> _e = [];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) =>
      _e.add(MapEntry(name, value.toString()));

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _e.removeWhere((x) => x.key.toLowerCase() == name.toLowerCase());
    add(name, value);
  }

  @override
  String? value(String name) {
    for (final x in _e) {
      if (x.key.toLowerCase() == name.toLowerCase()) return x.value;
    }
    return null;
  }

  @override
  List<String>? operator [](String name) {
    final v = value(name);
    return v == null ? null : [v];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    final g = <String, List<String>>{};
    for (final x in _e) {
      g.putIfAbsent(x.key.toLowerCase(), () => []).add(x.value);
    }
    g.forEach((n, vs) => action(n, vs));
  }

  @override
  void remove(String name, Object value) => _e.removeWhere((x) =>
      x.key.toLowerCase() == name.toLowerCase() && x.value == value.toString());

  @override
  void removeAll(String name) =>
      _e.removeWhere((x) => x.key.toLowerCase() == name.toLowerCase());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeHeaders: ${invocation.memberName}');
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
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeResponse: ${invocation.memberName}');
}

void main() {
  testWidgets(
      'App real (SwitchApp) + diálogo admin + teclado (paleta suave, escala 1.5) '
      'no lanza "infinite width"', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AccesibilidadService.instancia.cargar();
    AccesibilidadService.instancia.paletaSuave.value = true;
    AccesibilidadService.instancia.escalaTexto.value = 1.5;
    AccesibilidadService.instancia.blancoNegro.value = false;

    HttpOverrides.global = _FakeOverrides();
    await tester.binding.setSurfaceSize(const Size(360, 740));

    final List<String> errores = [];
    final handlerOriginal = FlutterError.onError;
    FlutterError.onError = (detalles) {
      errores.add(detalles.exceptionAsString());
      handlerOriginal?.call(detalles);
    };

    await tester.pumpWidget(SwitchApp(sesionInicial: const {
      'id': '1',
      'nombreCompleto': 'Vecino Uno',
      'dni': '11111112',
      'rol': 'VECINO',
    }));
    await tester.pumpAndSettle();

    // Toca la pestaña Admin → abre el diálogo login admin
    await tester.tap(find.text('Admin'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Acceso Admin'), findsOneWidget);

    // Escribe en el campo DNI con teclado real visible
    await tester.showKeyboard(find.byType(TextField).first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.enterText(find.byType(TextField).first, '11111111');
    await tester.pump();

    // Cambia a Contraseña y escribe
    await tester.enterText(find.byType(TextField).last, 'Switch2024!');
    await tester.pump();
    await tester.pumpAndSettle();

    // Cierra el teclado
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(Size.zero);
    tester.view.viewInsets = FakeViewPadding.zero;

    FlutterError.onError = handlerOriginal;

    for (var e in errores) {
      debugPrint('ERROR FLUJO: $e');
    }
    expect(
      errores.where((e) =>
          e.contains('infinite width') || e.contains('BoxConstraints forces')),
      isEmpty,
      reason: 'Se reprodujo "BoxConstraints forces an infinite width":\n'
          '${errores.take(5).join('\n---\n')}',
    );
  });
}
