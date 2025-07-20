import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../services/secure_storage_service.dart';

class QrGenerateScreen extends StatefulWidget {
  final String? wiban;
  const QrGenerateScreen({Key? key, this.wiban}) : super(key: key);

  @override
  State<QrGenerateScreen> createState() => _QrGenerateScreenState();
}

class _QrGenerateScreenState extends State<QrGenerateScreen> {
  String? _encodedData;
  String? _wiban;
  String? _firstName;
  String? _lastName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = SecureStorageService();
    String wiban = widget.wiban ?? '';
    if (wiban.isEmpty) {
      wiban = await storage.read('user_wiban') ?? '';
    }
    final firstName = await storage.getUserFirstName() ?? '';
    final lastName = await storage.getUserLastName() ?? '';
    final data = jsonEncode({
      'firstName': firstName,
      'lastName': lastName,
      'wiban': wiban,
    });
    setState(() {
      _encodedData = base64Encode(utf8.encode(data));
      _wiban = wiban;
      _firstName = firstName;
      _lastName = lastName;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Kodum')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _encodedData ?? '',
                      version: QrVersions.auto,
                      size: 240.0,
                      gapless: false,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      embeddedImageStyle: QrEmbeddedImageStyle(size: Size(40, 40)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
              
                ],
              ),
      ),
    );
  }
}
