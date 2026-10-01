abstract class IQrScannerService {
  Future<String?> escanearCodigo();
}

class QrScannerService implements IQrScannerService {
  @override
  Future<String?> escanearCodigo() async {
    // Simula la apertura de la cámara y escaneo exitoso
    await Future.delayed(const Duration(milliseconds: 500));
    return 'QR_HASH_DEMO_2026';
  }
}
