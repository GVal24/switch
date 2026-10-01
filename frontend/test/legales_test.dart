import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/legal_service.dart';
import 'package:frontend/widgets/legal_document_dialog.dart';

void main() {
  group('LegalService.aTextoPlano', () {
    test('arma un texto legible con título, versión, intro y cláusulas', () {
      final texto = LegalService.aTextoPlano({
        'titulo': 'Términos y Condiciones',
        'version': '1.0.0',
        'vigenteDesde': '2026-09-30',
        'intro': 'Este contrato regula el uso de la plataforma.',
        'secciones': [
          {
            'titulo': 'Cláusula Primera: Objeto',
            'cuerpo': [
              'Primer párrafo de la cláusula.',
              'Segundo párrafo de la cláusula.',
            ],
          },
        ],
      });

      expect(texto, contains('Términos y Condiciones'));
      expect(texto, contains('Versión 1.0.0'));
      expect(texto, contains('vigente desde 2026-09-30'));
      expect(texto, contains('Este contrato regula el uso de la plataforma.'));
      expect(texto, contains('Cláusula Primera: Objeto'));
      expect(texto, contains('Primer párrafo de la cláusula.'));
      expect(texto, contains('Segundo párrafo de la cláusula.'));
    });

    test('no rompe si faltan secciones o vienen vacías', () {
      final texto = LegalService.aTextoPlano({'titulo': 'Sólo título'});
      expect(texto, contains('Sólo título'));
    });

    test('tolera secciones mal formadas sin lanzar excepción', () {
      final texto = LegalService.aTextoPlano({
        'titulo': 'T',
        'secciones': [
          'no soy un mapa',
          {'titulo': 'Sin cuerpo', 'cuerpo': <dynamic>[]},
          {
            'cuerpo': [42, null, 'párrafo válido']
          },
        ],
      });
      expect(texto, contains('Sin cuerpo'));
      expect(texto, contains('párrafo válido'));
    });
  });

  group('LegalDocumentDialog', () {
    testWidgets('muestra un aviso de error si el documento no se puede bajar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegalDocumentDialog(
              idDocumento: 'terminos',
              tituloRespaldo: 'Términos y Condiciones',
            ),
          ),
        ),
      );

      // Primera pasada: el diálogo se monta y pide el documento.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Sin backend la petición falla, y el diálogo debe decirlo en vez
      // de mostrar un texto vacío que la persona pueda aceptar sin leer.
      expect(find.textContaining('No pudimos descargar'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);
    });

    testWidgets('ofrece el botón de cerrar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegalDocumentDialog(
              idDocumento: 'privacidad',
              tituloRespaldo: 'Política de Privacidad',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Política de Privacidad'), findsOneWidget);
      expect(find.text('CERRAR'), findsOneWidget);
    });
  });
}
