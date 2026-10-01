import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/screens/usuarios_bloqueados_screen.dart';
import 'package:frontend/screens/mensajes_contacto_screen.dart';
import 'package:frontend/screens/contacto_screen.dart';
import 'package:frontend/services/accesibilidad_service.dart';
import 'package:frontend/theme/app_theme.dart';

/// Respuestas con la misma forma que devuelve el backend real.
///
/// Las tres situaciones de bloqueo van separadas porque la pantalla las
/// explica de forma distinta: bloqueo permanente, penalización vigente y
/// penalización vencida.
const bloqueadosJson = '''
{"exito":true,"datos":{"bloqueados":[
 {"id":6,"dni":"27333455","nombre":"Diego","apellido":"Martinez","rol":"VECINO",
  "activo":false,"suspendido_hasta":null,"motivo_suspension":null,
  "deshabilitado":true,"suspendido":false,"suspension_vencida":false,
  "dias_restantes":null,"suspendido_hasta_legible":null,"creado_legible":"04/09/2026"},
 {"id":2,"dni":"38450912","nombre":"Guillermina","apellido":"Valdez","rol":"VECINO",
  "activo":true,"suspendido_hasta":"2026-10-08T00:37:10.432Z",
  "motivo_suspension":"posible imagen de menor",
  "deshabilitado":false,"suspendido":true,"suspension_vencida":false,
  "dias_restantes":6,"suspendido_hasta_legible":"07/10/2026 21:37","creado_legible":"04/09/2026"},
 {"id":9,"dni":"30111222","nombre":"Lucia","apellido":"Ferrer","rol":"VECINO",
  "activo":true,"suspendido_hasta":"2026-09-30T00:00:00.000Z",
  "motivo_suspension":"reporte justificado",
  "deshabilitado":false,"suspendido":false,"suspension_vencida":true,
  "dias_restantes":0,"suspendido_hasta_legible":"29/09/2026 21:00","creado_legible":"04/09/2026"}
 ],"total":3}}
''';

const bloqueadosVacioJson = '''
{"exito":true,"datos":{"bloqueados":[],"total":0}}
''';

const buzonJson = '''
{"exito":true,"datos":{"mensajes":[
 {"id":11,"asunto":"PREGUNTA","mensaje":"Como cambio la foto de perfil?",
  "respuesta":null,"leido":false,"autor_nombre":"Nico Paz","autor_dni":"29111333",
  "autor_telefono":"1122334455","usuario_id":7,"respondido_por":null,
  "creado_legible":"04/09/2026 09:10","respondido_en":null,"respondido_legible":null,
  "respondio_nombre":null},
 {"id":10,"asunto":"CONTACTO","mensaje":"Gracias por la ayuda",
  "respuesta":"De nada, cualquier cosa","leido":true,"autor_nombre":"Lucia Ferrer",
  "autor_dni":"30111222","autor_telefono":"1166778899","usuario_id":8,
  "respondido_por":1,"creado_legible":"03/09/2026 18:00",
  "respondido_en":"2026-09-03T21:00:00.000Z","respondido_legible":"03/09/2026 18:00",
  "respondio_nombre":"Admin"}
 ],"pendientes":1,"total":2}}
''';

/// Registra qué pidió cada pantalla, para verificar los endpoints de cada acción.
final List<String> peticiones = <String>[];

class _FakeHttpOverrides extends HttpOverrides {
  /// Si es false, la lista de bloqueados y el buzón llegan vacíos.
  final bool hayDatos;
  _FakeHttpOverrides({this.hayDatos = true});

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
  Future<HttpClientResponse> close() async {
    final datos = _respuesta();
    return _FakeResponse(datos.cuerpo, datos.status);
  }

  /// Cuerpo y código de la respuesta, porque no todos los endpoints devuelven
  /// 200: el que crea un mensaje devuelve 201 y el cliente lo exige.
  _Respuesta _respuesta() {
    final path = url.path;
    final metodo = method.toUpperCase();
    // Se anota la línea completa, con la query: el filtro de la bandeja se
    // diferencia del historial sólo por el parámetro, y `Uri.path` lo esconde.
    final cuerpo = _body.isEmpty ? '' : ' ${utf8.decode(_body)}';
    peticiones.add(
        '$metodo $path${url.hasQuery ? '?${url.query}' : ''}$cuerpo');

    if (path.endsWith('/admin/usuarios-bloqueados')) {
      return _ok(config.hayDatos ? bloqueadosJson : bloqueadosVacioJson);
    }
    if (path.endsWith('/admin/contacto/pendientes')) {
      return _ok(
          '{"exito":true,"datos":{"pendientes":${config.hayDatos ? 1 : 0}}}');
    }
    if (path.endsWith('/admin/contacto')) {
      return _ok(config.hayDatos
          ? buzonJson
          : '{"exito":true,"datos":{"mensajes":[],"pendientes":0}}');
    }
    if (path.contains('/admin/contacto/')) {
      return _ok(
          '{"exito":true,"mensaje":"Respuesta guardada.","datos":{"id":11,"respuesta":"x","leido":true}}');
    }
    if (path.endsWith('/admin/reactivar')) {
      return _ok(
          '{"exito":true,"mensaje":"Diego Martinez fue dado de alta nuevamente."}');
    }
    if (path.endsWith('/contacto')) {
      return _ok(
          '{"exito":true,"mensaje":"Mensaje enviado.","datos":{"id":12,"asunto":"PREGUNTA"}}',
          estado: 201);
    }

    return _ok('{"error":"not found"}');
  }

  static _Respuesta _ok(String cuerpo, {int estado = 200}) =>
      _Respuesta(cuerpo.codeUnits, estado);

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
  void writeln([Object? object = '']) =>
      _body.addAll('$object\n'.codeUnits);

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

  // El paquete http consulta y escribe estos valores en cada petición. Si
  // falta alguno, revienta con UnimplementedError antes de enviar nada.
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

class _Respuesta {
  final List<int> cuerpo;
  final int status;
  _Respuesta(this.cuerpo, this.status);
}

class _FakeResponse implements HttpClientResponse {
  final List<int> _data;
  final int _status;
  _FakeResponse(this._data, [this._status = 200]);

  @override
  int get statusCode => _status;

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

Future<void> _preparar(WidgetTester tester, {bool hayDatos = true}) async {
  SharedPreferences.setMockInitialValues({});
  await AccesibilidadService.instancia.cargar();
  await tester.binding.setSurfaceSize(const Size(412, 915));
  HttpOverrides.global = _FakeHttpOverrides(hayDatos: hayDatos);
  peticiones.clear();
  addTearDown(() {
    HttpOverrides.global = null;
    tester.binding.setSurfaceSize(null);
  });
}

void main() {
  group('Cuentas bloqueadas', () {
    testWidgets('Muestra las tres situaciones con su explicación',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(
          const MaterialApp(home: UsuariosBloqueadosScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Diego'), findsOneWidget);
      expect(find.text('CUENTA BLOQUEADA'), findsOneWidget);
      expect(find.textContaining('No puede entrar a la plataforma'),
          findsOneWidget);

      expect(find.text('PENALIZADA'), findsOneWidget);
      expect(find.textContaining('Le quedan 6 días'), findsOneWidget);

      expect(find.text('LA PENALIZACIÓN YA VENCIÓ'), findsOneWidget);
    });

    testWidgets('Aclarar que una penalización vencida se levanta sola',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(
          const MaterialApp(home: UsuariosBloqueadosScreen()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('levanta sola la próxima vez'),
        findsOneWidget,
      );
    });

    testWidgets('Muestra el motivo de la penalización',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(
          const MaterialApp(home: UsuariosBloqueadosScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Motivo: posible imagen de menor'),
          findsOneWidget);
    });

    testWidgets('Dar de alta pide confirmación y recién ahí llama al servidor',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(
          const MaterialApp(home: UsuariosBloqueadosScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DAR DE ALTA NUEVAMENTE').first);
      await tester.pumpAndSettle();

      // Todavía no se tocó el servidor: primero hay que confirmar.
      expect(find.text('¿Dar de alta a Diego Martinez?'), findsOneWidget);
      expect(find.textContaining('La cuenta vuelve a estar activa'),
          findsOneWidget);
      expect(peticiones.where((p) => p.contains('/admin/reactivar')), isEmpty);

      await tester.tap(find.text('DAR DE ALTA'));
      await tester.pumpAndSettle();

      final llamada =
          peticiones.where((p) => p.contains('/admin/reactivar')).toList();
      expect(llamada, hasLength(1));
      expect(llamada.first, contains('"usuarioId":6'));
    });

    testWidgets('Cancelar la confirmación no toca el servidor',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(
          const MaterialApp(home: UsuariosBloqueadosScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DAR DE ALTA NUEVAMENTE').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(peticiones.where((p) => p.contains('/admin/reactivar')), isEmpty);
    });

    testWidgets('Aclara que dar de alta no borra lo publicado antes',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(
          const MaterialApp(home: UsuariosBloqueadosScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DAR DE ALTA NUEVAMENTE').first);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Lo que la persona había publicado antes'),
        findsOneWidget,
      );
    });

    testWidgets('Sin cuentas bloqueadas avisa que no hay ninguna',
        (WidgetTester tester) async {
      await _preparar(tester, hayDatos: false);
      await tester.pumpWidget(
          const MaterialApp(home: UsuariosBloqueadosScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay ninguna cuenta bloqueada ni penalizada.'),
        findsOneWidget,
      );
    });
  });

  group('Buzón de mensajes', () {
    testWidgets('Muestra lo pendiente arriba y el historial abajo',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester
          .pumpWidget(const MaterialApp(home: MensajesContactoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nico Paz'), findsOneWidget);
      // "SIN RESPONDER" aparece dos veces: como filtro y como marca del
      // mensaje. Lo que importa es que el pendiente esté arriba del todo.
      expect(find.text('SIN RESPONDER'), findsWidgets);
      expect(find.text('Pregunta'), findsOneWidget);
      expect(find.text('Lucia Ferrer'), findsOneWidget);
      expect(find.text('RESPONDIDO'), findsOneWidget);
      expect(find.text('De nada, cualquier cosa'), findsOneWidget);

      // El pendiente va primero en la lista.
      final textos = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((t) => t != null)
          .toList();
      expect(
        textos.indexOf('Nico Paz') < textos.indexOf('Lucia Ferrer'),
        isTrue,
      );
    });

    testWidgets('Muestra el contacto del autor para poder responderle',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester
          .pumpWidget(const MaterialApp(home: MensajesContactoScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('DNI 29111333'), findsOneWidget);
      expect(find.textContaining('Tel 1122334455'), findsOneWidget);
    });

    testWidgets('El filtro cambia entre sin responder y todos',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester
          .pumpWidget(const MaterialApp(home: MensajesContactoScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TODOS'));
      await tester.pumpAndSettle();

      // El endpoint del filtro tiene que llevar el parámetro, si no el filtro
      // no cambia nada aunque la pantalla lo pida.
      expect(
        peticiones.where((p) => p.contains('/admin/contacto?pendientes=1')),
        isNotEmpty,
      );
    });

    testWidgets('Responder exige escribir algo y lo guarda',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester
          .pumpWidget(const MaterialApp(home: MensajesContactoScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('RESPONDER').first);
      await tester.pumpAndSettle();

      expect(find.text('Tu respuesta'), findsOneWidget);
      expect(find.textContaining('Le escribió Nico Paz'), findsOneWidget);

      // Hay un solo campo de texto en el diálogo, pero se busca el primero
      // explícitamente: `widgetWithText(TextField, '')` matchea todos.
      await tester.enterText(find.byType(TextField).first, 'Entrá a tu perfil');
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      final llamada = peticiones
          .where((p) => p.contains('/admin/contacto/11/responder'))
          .toList();
      expect(llamada, hasLength(1));
      expect(llamada.first, contains('Entrá a tu perfil'));
    });

    testWidgets('Una respuesta vacía no se envía',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester
          .pumpWidget(const MaterialApp(home: MensajesContactoScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('RESPONDER').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(peticiones.where((p) => p.contains('/responder')), isEmpty);
    });

    testWidgets('Un mensaje ya respondido se puede volver a responder',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester
          .pumpWidget(const MaterialApp(home: MensajesContactoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('CAMBIAR RESPUESTA'), findsOneWidget);
    });

    testWidgets('Sin mensajes avisa que nadie escribió nada',
        (WidgetTester tester) async {
      await _preparar(tester, hayDatos: false);
      await tester
          .pumpWidget(const MaterialApp(home: MensajesContactoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No hay mensajes esperando respuesta.'), findsOneWidget);
    });
  });

  group('Formulario de contacto', () {
    testWidgets('No envía un mensaje vacío', (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(const MaterialApp(home: ContactoScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ENVIAR MENSAJE'));
      await tester.pumpAndSettle();

      expect(peticiones.where((p) => p.contains('/contacto')), isEmpty);
      expect(find.textContaining('Escribí tu consulta antes de enviarla'),
          findsOneWidget);
    });

    testWidgets('Envía el mensaje con el motivo elegido',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(const MaterialApp(home: ContactoScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comentario'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField).first, 'MeiksisPrice es un genetically engine');
      await tester.pump();
      await tester.tap(find.text('ENVIAR MENSAJE'));
      await tester.pumpAndSettle();

      final llamada = peticiones.where((p) => p.contains('/contacto')).toList();
      expect(llamada, hasLength(1));
      expect(llamada.first, contains('"asunto":"COMENTARIO"'));
      expect(llamada.first, contains('engine'));
    });

    testWidgets('Cuenta los caracteres que quedan', (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(const MaterialApp(home: ContactoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('2000 caracteres'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'hola');
      await tester.pump();
      expect(find.text('1996 caracteres'), findsOneWidget);
    });

    testWidgets('Aclarar que va directo a la administración',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(const MaterialApp(home: ContactoScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text('Este mensaje va directo a la administración de Switch.'),
        findsOneWidget,
      );
    });

    testWidgets('Después de enviar avisa que ya lo leyeron',
        (WidgetTester tester) async {
      await _preparar(tester);
      await tester.pumpWidget(const MaterialApp(home: ContactoScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'hola');
      await tester.pump();
      await tester.tap(find.text('ENVIAR MENSAJE'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ya lo leímos'), findsOneWidget);
    });
  });

  group('Sin desbordarse en pantallas chicas', () {
    final temas = <String, ThemeData>{
      'estandar': AppTheme.temaEstandar,
      'accesible': AppTheme.temaVistaAccesible,
      'altoContraste': AppTheme.temaAltoContraste,
    };

    for (final entrada in temas.entries) {
      for (final escala in [1.0, 1.5]) {
        testWidgets(
            'Cuentas bloqueadas a 384dp sin ancho infinito '
            '(${entrada.key}, escala $escala)', (WidgetTester tester) async {
          SharedPreferences.setMockInitialValues({});
          await AccesibilidadService.instancia.cargar();
          await tester.binding.setSurfaceSize(const Size(384, 700));
          HttpOverrides.global = _FakeHttpOverrides();
          addTearDown(() {
            HttpOverrides.global = null;
            tester.binding.setSurfaceSize(null);
          });

          await tester.pumpWidget(MaterialApp(
            theme: entrada.value,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
            home: const UsuariosBloqueadosScreen(),
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });

        testWidgets(
            'Buzón a 384dp sin ancho infinito '
            '(${entrada.key}, escala $escala)', (WidgetTester tester) async {
          SharedPreferences.setMockInitialValues({});
          await AccesibilidadService.instancia.cargar();
          await tester.binding.setSurfaceSize(const Size(384, 700));
          HttpOverrides.global = _FakeHttpOverrides();
          addTearDown(() {
            HttpOverrides.global = null;
            tester.binding.setSurfaceSize(null);
          });

          await tester.pumpWidget(MaterialApp(
            theme: entrada.value,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
            home: const MensajesContactoScreen(),
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
