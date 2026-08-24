import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

/// Pantalla de escaneo de QR con la cámara real del teléfono.
/// Devuelve por Navigator.pop el texto contenido en el primer código
/// detectado (el hash de la institución), o null si se cancela.
class QrScannerScreen extends StatefulWidget {
  final String nombreInstitucion;

  const QrScannerScreen({Key? key, required this.nombreInstitucion})
      : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _procesado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_procesado || !mounted) return;
    for (final barcode in capture.barcodes) {
      final codigo = barcode.rawValue;
      if (codigo != null && codigo.trim().isNotEmpty) {
        _procesado = true;
        _controller.stop();
        Navigator.pop(context, codigo.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Escanear QR de ${widget.nombreInstitucion}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Alternar linterna',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Cambiar cámara',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Marco de guía con oscurecimiento alrededor
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 260,
                      height: 260,
                      margin: const EdgeInsets.only(bottom: 60),
                      decoration: BoxDecoration(
                        color: Colors.red, // Cualquier color: se recorta
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              margin: const EdgeInsets.only(bottom: 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.acentoVerdeEco, width: 3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'Apuntá al QR impreso en la institución para validar tu presencia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
