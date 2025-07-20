import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert'; // Added for base64Decode and jsonDecode

class QrScanScreen extends StatefulWidget {
  @override
  _QrScanScreenState createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Kod Tara')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final String? code = barcode.rawValue;
                debugPrint('QR okundu: $code');
                if (!_scanned && code != null && code.isNotEmpty) {
                  _scanned = true;
                  try {
                    final decodedStr = utf8.decode(base64Decode(code));
                    final decodedJson = jsonDecode(decodedStr);
                    if (decodedJson is Map && decodedJson['wiban'] != null) {
                      Navigator.of(context).pop({
                        'wiban': decodedJson['wiban'],
                        'firstName': decodedJson['firstName'],
                        'lastName': decodedJson['lastName'],
                      });
                    } else {
                      Navigator.of(context).pop({'wiban': decodedStr});
                    }
                  } catch (e) {
                    Navigator.of(context).pop({'wiban': ''});
                  }
                  break;
                }
              }
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'QR kodu kare alana hizalayın',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 