import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Ekran skanowania kodu kreskowego kamerą (`mobile_scanner`).
///
/// Po wykryciu pierwszego kodu zwraca go przez `Navigator.pop`, a wołający
/// (ekran skanera) wypełnia nim pole i pobiera produkt. Działa na Androidzie
/// i w przeglądarce; na Windows desktop kamera nie jest wspierana.
///
/// Własny [MobileScanner.errorBuilder] pokazuje realny powód błędu (domyślny
/// widget pluginu w wersji release ukrywa go za ogólnym komunikatem).
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  // Chroni przed wielokrotnym zamknięciem przy serii wykryć.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(code.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skanuj kod')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (context, error, child) => _ScannerError(
          error: error,
          onRetry: () => _controller.start(),
        ),
        overlayBuilder: (context, constraints) => _Viewfinder(),
      ),
    );
  }
}

/// Nakładka: ramka celownika i podpowiedź.
class _Viewfinder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Text(
              'Skieruj aparat na kod kreskowy produktu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Czytelny ekran błędu kamery z konkretną poradą i przyciskiem „Spróbuj ponownie".
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final (title, hint) = _describe(error.errorCode);
    final detail = error.errorDetails?.message;

    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '($detail)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Zwraca (tytuł, poradę) po polsku dla danego kodu błędu.
  (String, String) _describe(MobileScannerErrorCode code) {
    switch (code) {
      case MobileScannerErrorCode.permissionDenied:
        return (
          'Brak zgody na aparat',
          'Wejdź w Ustawienia telefonu → Aplikacje → frapi → Uprawnienia '
              'i włącz dostęp do aparatu. Potem wróć tu i stuknij '
              '„Spróbuj ponownie".',
        );
      case MobileScannerErrorCode.unsupported:
        return (
          'Skanowanie niewspierane',
          'Ten telefon nie obsługuje skanowania kamerą. Możesz wpisać kod '
              'ręcznie lub dodać produkt ze zdjęcia etykiety.',
        );
      case MobileScannerErrorCode.controllerAlreadyInitialized:
      case MobileScannerErrorCode.controllerUninitialized:
      case MobileScannerErrorCode.controllerDisposed:
      case MobileScannerErrorCode.genericError:
        return (
          'Nie udało się uruchomić aparatu',
          'Sprawdź, czy aplikacja ma zgodę na aparat i czy nie używa go inna '
              'aplikacja, a potem stuknij „Spróbuj ponownie".',
        );
    }
  }
}
