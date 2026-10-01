import 'package:flutter/material.dart';

import '../services/legal_service.dart';
import '../theme/app_theme.dart';

/// Muestra un documento legal completo, descargado del backend.
///
/// La pantalla va pidiendo el texto mientras muestra un indicador, porque
/// son documentos largos y la descarga puede tardar.
class LegalDocumentDialog extends StatefulWidget {
  final String idDocumento;
  final String tituloRespaldo;

  const LegalDocumentDialog({
    Key? key,
    required this.idDocumento,
    required this.tituloRespaldo,
  }) : super(key: key);

  @override
  State<LegalDocumentDialog> createState() => _LegalDocumentDialogState();
}

class _LegalDocumentDialogState extends State<LegalDocumentDialog> {
  Map<String, dynamic>? _documento;
  bool _cargando = true;
  bool _fallo = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final doc = await LegalService.obtenerDocumento(widget.idDocumento);
    if (!mounted) return;
    setState(() {
      _documento = doc;
      _cargando = false;
      _fallo = doc == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.superficieTarjeta,
      title: Text(
        widget.tituloRespaldo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textoClaro,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: _construirContenido(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'CERRAR',
            style: TextStyle(color: AppTheme.acentoVerdeEco),
          ),
        ),
      ],
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fallo || _documento == null) {
      // No se muestra un diálogo vacío: si el texto no se pudo descargar,
      // se dice explícitamente para que nadie acepte a ciegas.
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No pudimos descargar este documento.',
              style: TextStyle(
                color: AppTheme.textoClaro,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisá tu conexión y volvé a intentar. No vas a poder aceptar '
              'los términos sin poder leerlos.',
              style: TextStyle(color: AppTheme.textoSecundario, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _fallo = false;
                });
                _cargar();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      );
    }

    final texto = LegalService.aTextoPlano(_documento!);
    return SingleChildScrollView(
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: AppTheme.textoSecundario,
        ),
      ),
    );
  }
}
