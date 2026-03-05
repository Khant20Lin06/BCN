import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ItemScanPage extends StatefulWidget {
  const ItemScanPage({super.key});

  @override
  State<ItemScanPage> createState() => _ItemScanPageState();
}

class _ItemScanPageState extends State<ItemScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    String? value;
    for (final Barcode barcode in capture.barcodes) {
      final String candidate = (barcode.rawValue ?? '').trim();
      if (candidate.isNotEmpty) {
        value = candidate;
        break;
      }
    }

    if (value == null || value.isEmpty) {
      return;
    }

    _handled = true;
    Navigator.of(context).pop<String>(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode / QR')),
      body: Stack(
        children: <Widget>[
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.45),
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Point camera at barcode or QR code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
