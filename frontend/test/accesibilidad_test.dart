import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/services/accesibilidad_service.dart';

void main() {
  testWidgets('Navegación a Accesibilidad y uso de sus controles no lanza errores',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AccesibilidadService.instancia.cargar();

    final List<FlutterErrorDetails> errores = [];
    final handlerOriginal = FlutterError.onError;
    FlutterError.onError = (detalles) {
      errores.add(detalles);
      handlerOriginal?.call(detalles);
    };

    await tester.pumpWidget(const SwitchApp(sesionInicial: null));
    await tester.pumpAndSettle();

    // Navega a la pestaña Accesibilidad (índice 3 del BottomNavigationBar)
    await tester.tap(find.text('Accesibilidad'));
    await tester.pumpAndSettle();

    // Mueve el slider de tamaño de texto
    final slider = find.byType(Slider);
    if (slider.evaluate().isNotEmpty) {
      await tester.drag(slider.first, const Offset(80, 0));
      await tester.pumpAndSettle();
    }

    // Activa los switches de paleta (con scroll hasta cada uno)
    for (final texto in ['Paleta suave y calma', 'Alto contraste', 'Blanco y negro puro']) {
      final sw = find.widgetWithText(SwitchListTile, texto);
      if (sw.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(sw.first, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(sw.first);
        await tester.pumpAndSettle();
      }
    }

    // Restablece todo
    final restablecer = find.text('RESTABLECER TODO');
    if (restablecer.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(restablecer.first, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(restablecer.first);
      await tester.pumpAndSettle();
    }

    // Alterna la vista accesible desde el AppBar
    final botonAcc = find.byType(Tooltip).first;
    await tester.tap(botonAcc);
    await tester.pumpAndSettle();
    await tester.tap(botonAcc);
    await tester.pumpAndSettle();

    // Cambia a otras pestañas y vuelve
    for (final tab in ['Voluntariado', 'Catálogo P2P', 'Mi Perfil', 'Accesibilidad']) {
      final t = find.text(tab);
      if (t.evaluate().isNotEmpty) {
        await tester.tap(t.first);
        await tester.pumpAndSettle();
      }
    }

    FlutterError.onError = handlerOriginal;

    final erroresDeClave = errores
        .where((e) => e.toString().contains('GlobalKey') || e.toString().contains('same key'))
        .toList();
    expect(erroresDeClave, isEmpty,
        reason: 'Se detectaron errores de claves duplicadas: '
            '${erroresDeClave.map((e) => e.toString()).take(3).join('\n---\n')}');
  });
}
