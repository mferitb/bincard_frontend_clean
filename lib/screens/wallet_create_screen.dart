import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/custom_message.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class WalletCreateScreen extends StatefulWidget {
  const WalletCreateScreen({super.key});

  @override
  State<WalletCreateScreen> createState() => _WalletCreateScreenState();
}

class _WalletCreateScreenState extends State<WalletCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _nationalIdController = TextEditingController();
  DateTime? _birthDate;
  final _motherNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  String? _gender;
  File? _frontPhoto;
  File? _backPhoto;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nationalIdController.dispose();
    _motherNameController.dispose();
    _fatherNameController.dispose();
    _serialNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontPhoto = File(picked.path);
        } else {
          _backPhoto = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _frontPhoto == null || _backPhoto == null) return;
    setState(() { _isLoading = true; });
    try {
      final api = ApiService();
      final accessToken = await SecureStorageService().getAccessToken();
      final formData = FormData.fromMap({
        'nationalId': _nationalIdController.text.trim(),
        'birthDate': _birthDate != null ? _birthDate!.toIso8601String().split('T').first : '',
        'motherName': _motherNameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'gender': _gender,
        'serialNumber': _serialNumberController.text.trim(),
        'frontCardPhoto': await MultipartFile.fromFile(_frontPhoto!.path, filename: 'front.jpg'),
        'backCardPhoto': await MultipartFile.fromFile(_backPhoto!.path, filename: 'back.jpg'),
      });
      final response = await api.dio.post(
        ApiConstants.baseUrl + ApiConstants.createWalletEndpoint,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          contentType: 'multipart/form-data',
          sendTimeout: Duration(seconds: 90),
          receiveTimeout: Duration(seconds: 90),
        ),
      );
      if (response.data['success'] == true) {
        if (mounted) {
          CustomMessage.show(
            context,
            message: 'Cüzdan başarıyla oluşturuldu!',
            type: MessageType.success,
          );
        }
      } else {
        _showError(response.data['message'] ?? 'Cüzdan oluşturulamadı.');
      }
    } catch (e) {
      _showError('Cüzdan oluşturulurken hata oluştu.');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    CustomMessage.show(
      context,
      message: message,
      type: MessageType.error,
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Kimlik Bilgileri'),
        isActive: _currentStep >= 0,
        content: Column(
          children: [
            TextFormField(
              controller: _nationalIdController,
              decoration: const InputDecoration(labelText: 'T.C. Kimlik No'),
              keyboardType: TextInputType.number,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (v) {
                if (v == null || v.length != 11) return '11 haneli T.C. Kimlik No girin';
                if (!RegExp(r'^\d{11}').hasMatch(v)) return 'Sadece rakam girin';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Doğum Tarihi (yyyy-MM-dd)'),
              keyboardType: TextInputType.number,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'\d|-')),
                _DateFormatter(),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Doğum tarihi zorunlu';
                if (!RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(v)) return 'Tarih formatı yyyy-MM-dd olmalı';
                return null;
              },
              onChanged: (v) {
                try {
                  _birthDate = DateTime.parse(v);
                } catch (_) {
                  _birthDate = null;
                }
              },
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Aile Bilgileri'),
        isActive: _currentStep >= 1,
        content: Column(
          children: [
            TextFormField(
              controller: _motherNameController,
              decoration: const InputDecoration(labelText: 'Anne Adı'),
              validator: (v) => v == null || v.isEmpty ? 'Anne adı zorunlu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fatherNameController,
              decoration: const InputDecoration(labelText: 'Baba Adı'),
              validator: (v) => v == null || v.isEmpty ? 'Baba adı zorunlu' : null,
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Cinsiyet ve Seri No'),
        isActive: _currentStep >= 2,
        content: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Erkek')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Kadın')),
              ],
              onChanged: (v) => setState(() => _gender = v),
              decoration: const InputDecoration(labelText: 'Cinsiyet'),
              validator: (v) => v == null ? 'Cinsiyet seçin' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serialNumberController,
              decoration: const InputDecoration(labelText: 'Seri No'),
              maxLength: 9,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Seri no zorunlu';
                if (v.length != 9) return 'Seri no 9 karakter olmalı';
                if (!RegExp(r'^[A-Za-z0-9]{9}').hasMatch(v)) return 'Sadece harf ve rakam girin';
                return null;
              },
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Kimlik Fotoğrafları'),
        isActive: _currentStep >= 3,
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Ön Yüz'),
                      const SizedBox(height: 8),
                      _frontPhoto == null
                          ? OutlinedButton.icon(
                              onPressed: () => _pickImage(true),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Çek'),
                            )
                          : Image.file(_frontPhoto!, height: 100),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Arka Yüz'),
                      const SizedBox(height: 8),
                      _backPhoto == null
                          ? OutlinedButton.icon(
                              onPressed: () => _pickImage(false),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Çek'),
                            )
                          : Image.file(_backPhoto!, height: 100),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Sadece kamera ile fotoğraf çekebilirsiniz. Galeriden seçim yapılamaz.'),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cüzdan Oluştur'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < _buildSteps().length - 1) {
                    setState(() => _currentStep++);
                  } else {
                    _submit();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) setState(() => _currentStep--);
                },
                steps: _buildSteps(),
                controlsBuilder: (context, details) {
                  return Row(
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Geri'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(_currentStep == _buildSteps().length - 1 ? 'Oluştur' : 'İleri'),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('-', '');
    if (text.length > 8) text = text.substring(0, 8);
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 3 || i == 5) buffer.write('-');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
} 