import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/screens/moderacion_screen.dart';
import 'package:frontend/services/accesibilidad_service.dart';
import 'package:frontend/theme/app_theme.dart';

/// Respuestas con la misma forma que devuelve el backend real.
const colaJson = '''
{"exito":true,"mensaje":"Cada imagen debe revisarse una por una.","datos":{
 "pendientes":[
  {"id":31,"publicacion_id":44,"tipo_revision":"IMAGEN","titulo":"Bicicleta de 26",
   "descripcion":"Almost new, cambiar por algo de jardineria",
   "autor_nombre":"Lucia","autor_apellido":"Ferrer","autor_dni":"30111222",
   "url_para_moderar":"/api/admin/moderacion/31/imagen",
   "filtro_motivos":["METADATOS_EXIF_ELIMINADOS"],
   "creado_legible":"04/09/2026 08:24"},
  {"id":null,"publicacion_id":45,"tipo_revision":"TEXTO","titulo":"Clases de ingles",
   "descripcion":"Basico, tengo dos lugares",
   "autor_nombre":"Nico","autor_apellido":"Paz","autor_dni":"29111333",
   "url_para_moderar":null,"filtro_motivos":[],
   "creado_legible":"04/09/2026 09:10"}
 ],
 "total":2}}
''';

const colaVaciaJson = '''
{"exito":true,"datos":{"pendientes":[],"total":0}}
''';

const estadisticasJson = '''
{"exito":true,"datos":{"pendientes":2,"aprobadas":11,"rechazadas":3,"con_menores":1}}
''';

const textoJson = '{"exito":true}';

/// Registra qué pidió la pantalla, para verificar los endpoints de cada acción.
final List<String> peticiones = <String>[];

/// Sirve una imagen válida de 1x1 (PNG transparente) para el preview.
final List<int> png1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _FakeHttpOverrides extends HttpOverrides {
  /// Si es false, la cola responde vacía (estado "todo revisado").
  final bool hayPendientes;
  _FakeHttpOverrides({this.hayPendientes = true});

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(this);
}

class _FakeHttpClient implements HttpClient {
  final _FakeHttpOverrides config;
  _FakeHttpClient(this.config);

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
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest(url, config);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeRequest(url, config);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Método no soportado: ${invocation.memberName}');
  }
}

class _FakeRequest implements HttpClientRequest {
  final Uri url;
  final _FakeHttpOverrides config;
  _FakeRequest(this.url, this.config);

  final List<int> _body = [];

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(_respuesta());

  List<int> _respuesta() {
    final path = url.path;
    final metodo = method.toUpperCase();

    if (path.endsWith('/admin/moderacion/pendientes')) {
      return _utf8(config.hayPendientes ? colaJson : colaVaciaJson);
    }
    if (path.endsWith('/admin/moderacion/estadisticas')) {
      return _utf8(config.hayPendientes
          ? estadisticasJson
          : '{"exito":true,"datos":{"pendientes":0,"aprobadas":11,"rechazadas":3,"con_menores":1}}');
    }
    if (path.endsWith('/imagen')) {
      return png1x1;
    }

    // Acciones de moderación.
    if (path.contains('/admin/moderacion/')) {
      peticiones
          .add('$metodo $path${_body.isEmpty ? '' : ' ${utf8.decode(_body)}'}');
      return _utf8(
          '{"exito":true,"mensaje":"Hecho.","datos":{"id":1,"publicacion_id":44}}');
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
    throw UnimplementedError('Método no soportado: ${invocation.memberName}');
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
    throw UnimplementedError('Método no soportado: ${invocation.memberName}');
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
  Future<E> drain<E>([E? futureValue]) async => futureValue!;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Método no soportado: ${invocation.memberName}');
  }
}

/// Monta la pantalla y espera a que termine la carga inicial.
Future<void> _montar(WidgetTester tester, {bool hayPendientes = true}) async {
  SharedPreferences.setMockInitialValues({});
  await AccesibilidadService.instancia.cargar();
  await tester.binding.setSurfaceSize(const Size(412, 915));
  HttpOverrides.global = _FakeHttpOverrides(hayPendientes: hayPendientes);

  await tester.pumpWidget(const MaterialApp(home: ModeracionScreen()));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => peticiones.clear());

  testWidgets('Muestra las publicaciones pendientes con autor y tipo',
      (WidgetTester tester) async {
    await _montar(tester);

    expect(find.text('Bicicleta de 26'), findsOneWidget);
    expect(find.text('Clases de ingles'), findsOneWidget);

    expect(find.text('CON IMAGEN'), findsOneWidget);
    expect(find.text('SIN IMAGEN'), findsOneWidget);

    // Autoría visible: sirve para que la moderación tenga contexto humano.
    expect(find.text('De: Lucia Ferrer · DNI 30111222'), findsOneWidget);
    expect(find.text('De: Nico Paz · DNI 29111333'), findsOneWidget);

    // El motivo técnico se traduce a lenguaje llano.
    expect(
      find.text('Se le sacaron los datos EXIF (pueden traer GPS)'),
      findsOneWidget,
    );

    // El texto de una publicación sin imagen se puede leer en la cola.
    expect(find.text('Basico, tengo dos lugares'), findsOneWidget);
  });

  testWidgets('Una publicación sin imagen no ofrece ver imagen',
      (WidgetTester tester) async {
    await _montar(tester);

    expect(find.text('VER LA IMAGEN'), findsOneWidget);
  });

  testWidgets('Aprobar pide confirmación y al confirmar publica la imagen',
      (WidgetTester tester) async {
    await _montar(tester);

    await tester.tap(find.text('APROBAR').first);
    await tester.pumpAndSettle();

    expect(find.text('¿Publicar esta publicación?'), findsOneWidget);
    expect(find.text('SÍ, PUBLICAR'), findsOneWidget);

    await tester.tap(find.text('SÍ, PUBLICAR'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      peticiones.first,
      contains('/admin/moderacion/31/aprobar'),
      reason: 'Debe aprobar por el id de moderación, no por el de publicación.',
    );
  });

  testWidgets('Cancelar la confirmación no toca el servidor',
      (WidgetTester tester) async {
    await _montar(tester);

    await tester.tap(find.text('APROBAR').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();

    expect(peticiones, isEmpty);
  });

  testWidgets('Rechazar exige escribir el motivo y lo envía',
      (WidgetTester tester) async {
    await _montar(tester);

    await tester.tap(find.text('RECHAZAR').first);
    await tester.pumpAndSettle();

    expect(find.text('¿Por qué se rechaza?'), findsOneWidget);

    // Sin motivo no se puede confirmar.
    await tester.tap(find.text('RECHAZAR').last);
    await tester.pumpAndSettle();
    expect(peticiones, isEmpty);
    expect(find.text('¿Por qué se rechaza?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Foto borrosa e ilegible');
    await tester.tap(find.text('RECHAZAR').last);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(peticiones.first, contains('/admin/moderacion/31/rechazar'));
    expect(peticiones.first, contains('Foto borrosa e ilegible'));
  });

  testWidgets('El hallazgo de posible menor avisa que el archivo se conserva',
      (WidgetTester tester) async {
    await _montar(tester);

    await tester.tap(find.text('Es una imagen de menor de edad').first);
    await tester.pumpAndSettle();

    // El texto tiene que explicar la consecuencia legal, no sólo el botón.
    expect(find.textContaining('NO se borra'), findsOneWidget);
    expect(find.textContaining('Ley 26.061'), findsOneWidget);

    await tester.tap(find.text('SÍ, ES UN MENOR'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(peticiones.first, contains('/admin/moderacion/31/rechazar-menor'));
  });

  testWidgets('Ver la imagen descarga los bytes con sesión y las muestra',
      (WidgetTester tester) async {
    await _montar(tester);

    await tester.tap(find.text('VER LA IMAGEN'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    // Y se cierra.
    await tester.tap(find.text('CERRAR'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('Con la cola vacía avisa que no hay nada esperando',
      (WidgetTester tester) async {
    await _montar(tester, hayPendientes: false);

    expect(find.text('No hay nada esperando revisión'), findsOneWidget);
    expect(find.text('Todo revisado. No hay publicaciones esperando.'),
        findsOneWidget);
    expect(find.text('APROBAR'), findsNothing);
  });

  // El filtro automático NO puede detectar menores. La pantalla tiene que
  // dejarlo claro para que nadie confie en él y apruebe a ciegas.
  testWidgets('Aclara que el filtro no detecta menores de edad',
      (WidgetTester tester) async {
    await _montar(tester);

    expect(find.textContaining('NO puede detectar si hay'), findsOneWidget);
    expect(find.textContaining('eso lo decide una persona'), findsOneWidget);
  });

  testWidgets('El aviso de papel NO inventa capacidades de detección',
      (WidgetTester tester) async {
    await _montar(tester);

    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');

    expect(textos.toLowerCase(), isNot(contains('detecta autom')));
    expect(textos.toLowerCase(), isNot(contains('inteligencia artificial')));
    expect(textos.toLowerCase(), isNot(contains('reconocimiento facial')));
  });

  // Regresión del crash de ancho infinito del panel admin (ver
  // admin_dashboard_repro_test.dart: AppTheme usa minimumSize con
  // Size(double.infinity, N), que revienta dentro de Row/Wrap).
  final Map<String, ThemeData> temas = <String, ThemeData>{
    'temaEstandar': AppTheme.temaEstandar,
    'temaVistaAccesible': AppTheme.temaVistaAccesible,
    'temaAltoContraste': AppTheme.temaAltoContraste,
    'temaPaletaSuave': AppTheme.temaPaletaSuave,
  };

  temas.forEach((String nombreTema, ThemeData tema) {
    for (final double escala in <double>[1.0, 1.5]) {
      testWidgets(
          'Cola de moderación a 384dp sin ancho infinito '
          '($nombreTema, escala $escala)', (WidgetTester tester) async {
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
          home: const ModeracionScreen(modoAccesibleActivo: true),
        ));

        await tester.pump(const Duration(seconds: 1));
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }

        expect(find.text('Bicicleta de 26'), findsOneWidget);
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
