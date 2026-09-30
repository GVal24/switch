import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/services/accesibilidad_service.dart';

void main() {
  testWidgets('Diálogo login admin con teclado: no debe lanzar "infinite width"',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AccesibilidadService.instancia.cargar();
    // Reproduce el entorno real del usuario: paleta suave activada
    AccesibilidadService.instancia.paletaSuave.value = true;
    await tester.binding.setSurfaceSize(const Size(412, 915));

    final List<String> errores = [];
    final handlerOriginal = FlutterError.onError;
    FlutterError.onError = (detalles) {
      errores.add(detalles.exceptionAsString());
      handlerOriginal?.call(detalles);
    };

    // Sesión de vecino normal para llegar a la pestaña Admin
    final Map<String, dynamic> vecino = {
      'id': '2',
      'rol': 'VECINO',
      'nombreCompleto': 'Vecino Test',
      'nombre': 'Vecino Test',
    };

    await tester.pumpWidget(SwitchApp(sesionInicial: vecino));
    await tester.pumpAndSettle();

    // Ir a la pestaña Admin -> abre el diálogo de login
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Acceso Admin'), findsOneWidget);

    final campos = find.byType(TextField);
    expect(campos, findsNWidgets(2),
        reason: 'El diálogo debe tener 2 TextField (DNI y Contraseña)');

    // Enfocar el campo DNI y simular el teclado visible
    await tester.tap(campos.first);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.viewPadding = const FakeViewPadding(bottom: 0);
    await tester.pumpAndSettle();

    // Cerrar teclado
    tester.view.viewInsets = FakeViewPadding.zero;
    tester.view.viewPadding = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    // Escribir algo y enfocar el campo de contraseña
    await tester.enterText(campos.first, '11111111');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    FlutterError.onError = handlerOriginal;

    for (var e in errores) {
      debugPrint('ERROR CAPTURADO: $e');
    }
    expect(
      errores.where((e) => e.contains('infinite width') || e.contains('BoxConstraints forces')),
      isEmpty,
      reason: 'Se reprodujo "BoxConstraints forces an infinite width":\n'
          '${errores.take(5).join('\n---\n')}',
    );
  });
}