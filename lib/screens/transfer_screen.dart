import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import '../routes.dart';
import 'qr_generate_screen.dart';
import 'qr_scan_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert'; // Added for base64Decode
import 'dart:async'; // Timer için import

class TransferScreen extends StatefulWidget {
  final String wiban; // Kullanıcının kendi wiban'ı

  const TransferScreen({Key? key, required this.wiban}) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int _selectedTransferMethod = 0; // 0: NFC, 1: QR Kod
  int _selectedCardIndex = 0;
  bool _isLoading = false; // Transfer işlemi sırasında loading durumu
  Timer? _debounceTimer; // Debounce timer
  int _currentStep = 0; // Mevcut adım
  final int _totalSteps = 5; // Toplam adım sayısı (ön izleme dahil)
  final List<Map<String, dynamic>> _myCards = [
    {
      'name': 'Şehir Kartı',
      'number': '5312 **** **** 3456',
      'balance': '257,50 ₺',
      'color': AppTheme.blueGradient,
    },
    {
      'name': 'İkinci Kartım',
      'number': '4728 **** **** 9012',
      'balance': '125,75 ₺',
      'color': AppTheme.greenGradient,
    },
  ];
  Map<String, dynamic>? _walletData;
  String? _walletError;
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  String? _receiverName; // Alıcı ad soyad

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() { _walletError = null; });
    try {
      final api = ApiService();
      final accessToken = await SecureStorageService().getAccessToken();
      final response = await api.get(
        ApiConstants.myWalletEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.data['success'] == false && response.data['message'] != null) {
        setState(() {
          _walletData = null;
          _walletError = response.data['message'];
        });
      } else {
        setState(() {
          _walletData = response.data;
          _walletError = null;
        });
      }
    } catch (e) {
      setState(() {
        _walletData = null;
        _walletError = 'Cüzdan bilgisi alınamadı';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _receiverController.dispose();
    _debounceTimer?.cancel(); // Timer'ı temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Para Transferi',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepperHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildCurrentStepContent(),
              ),
            ),
            _buildStepperNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive 
                          ? AppTheme.primaryColor 
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? AppTheme.primaryColor 
                          : Colors.grey.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1TransferMethod();
      case 1:
        return _buildStep2SenderCard();
      case 2:
        return _buildStep3ReceiverDetails();
      case 3:
        return _buildStep4TransferDetails();
      case 4:
        return _buildStep5Preview();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepperNavigation() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Geri'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const Text('İşleniyor...')
                  : Text(_currentStep == _totalSteps - 1 ? 'Transferi Gönder' : 'İleri'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextStep() {
    if (_currentStep == _totalSteps - 1) {
      _handleTransfer();
    } else {
      // Son adımdan önce form validasyonu yap
      if (_currentStep == 3) {
        if (!_validateTransferForm()) {
          return;
        }
      }
      setState(() {
        _currentStep++;
      });
    }
  }

  bool _validateTransferForm() {
    // Transfer form validasyonu
    if (_receiverController.text.trim().isEmpty) {
      _showErrorDialog('Alıcı bilgisi zorunludur');
      return false;
    }
    if (_receiverNameController.text.trim().isEmpty) {
      _showErrorDialog('Alıcı ad soyad zorunludur');
      return false;
    }
    if (_amountController.text.trim().isEmpty) {
      _showErrorDialog('Transfer tutarı zorunludur');
      return false;
    }
    try {
      double amount = double.parse(_amountController.text.replaceAll(',', '.'));
      if (amount <= 0) {
        _showErrorDialog('Tutar 0\'dan büyük olmalıdır');
        return false;
      }
    } catch (e) {
      _showErrorDialog('Geçerli bir tutar girin');
      return false;
    }
    return true;
  }

  Widget _buildStep1TransferMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Transfer Yöntemi Seçin'),
        const SizedBox(height: 16),
        _buildTransferMethodSelector(),
      ],
    );
  }

  Widget _buildStep2SenderCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gönderen Cüzdan'),
        const SizedBox(height: 16),
        _buildCardSelector(),
      ],
    );
  }

  Widget _buildStep3ReceiverDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Alıcı Bilgileri'),
        const SizedBox(height: 16),
        _buildReceiverDetails(),
      ],
    );
  }

  Widget _buildStep4TransferDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Transfer Detayları'),
        const SizedBox(height: 16),
        _buildTransferAmountAndNote(),
      ],
    );
  }

  Widget _buildStep5Preview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Transfer Ön İzleme'),
        const SizedBox(height: 16),
        _buildPreviewCard(),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transfer Yöntemi
          _buildPreviewRow(
            icon: _selectedTransferMethod == 0 ? Icons.nfc : Icons.qr_code,
            title: 'Transfer Yöntemi',
            value: _selectedTransferMethod == 0 ? 'WIBAN ile Transfer' : 'QR Kod ile Transfer',
          ),
          const Divider(height: 24),
          
          // Gönderen Cüzdan
          _buildPreviewRow(
            icon: Icons.account_balance_wallet,
            title: 'Gönderen Cüzdan',
            value: _walletData != null ? 'Bakiye: ${_walletData!['balance']} ₺' : 'Cüzdan bilgisi alınamadı',
          ),
          const Divider(height: 24),
          
          // Alıcı Bilgileri
          _buildPreviewRow(
            icon: Icons.person,
            title: 'Alıcı Bilgisi',
            value: _receiverController.text.trim(),
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            icon: Icons.account_circle,
            title: 'Alıcı Ad Soyad',
            value: _receiverNameController.text.trim(),
          ),
          const Divider(height: 24),
          
          // Transfer Detayları
          _buildPreviewRow(
            icon: Icons.money,
            title: 'Transfer Tutarı',
            value: '${_amountController.text} ₺',
            valueColor: AppTheme.primaryColor,
            valueFontWeight: FontWeight.bold,
          ),
          if (_noteController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPreviewRow(
              icon: Icons.note,
              title: 'Açıklama',
              value: _noteController.text.trim(),
            ),
          ],
          const SizedBox(height: 24),
          
          // Uyarı Mesajı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transfer işlemi geri alınamaz. Bilgileri kontrol edin.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? AppTheme.textPrimaryColor,
                  fontWeight: valueFontWeight ?? FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiverDetails() {
    return Column(
      children: [
        _buildTextField(
          controller: _receiverController,
          label: 'Alıcı Bilgisi',
          hint: 'WIBAN, Telefon, E-posta veya Kimlik No',
          prefixIcon: Icons.person,
          onChanged: (value) async {
            if (value.isNotEmpty && value.length >= 8) {
              await _fetchReceiverName(value);
            } else {
              setState(() {
                _receiverName = null;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Alıcı bilgisi zorunlu';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _receiverNameController,
          label: 'Ad Soyad',
          hint: _receiverName != null && _receiverName!.isNotEmpty ? _receiverName! : 'Alıcının adı ve soyadı',
          prefixIcon: Icons.account_circle,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Alıcı ad soyad zorunludur';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTransferAmountAndNote() {
    return Column(
      children: [
        _buildTextField(
          controller: _amountController,
          label: 'Transfer Tutarı',
          hint: '0.00',
          prefixIcon: Icons.money,
          suffixText: '₺',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen bir tutar girin';
            }
            try {
              double amount = double.parse(value.replaceAll(',', '.'));
              if (amount <= 0) {
                return 'Tutar 0\'dan büyük olmalıdır';
              }
            } catch (e) {
              return 'Geçerli bir tutar girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _noteController,
          label: 'Açıklama (İsteğe bağlı)',
          hint: 'Transfer için bir açıklama ekleyin',
          prefixIcon: Icons.note,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTransferMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMethodButton(
              icon: Icons.nfc,
              title: 'NFC ile Transfer',
              isSelected: _selectedTransferMethod == 0,
              onTap: () {
                setState(() {
                  _selectedTransferMethod = 0;
                });
              },
            ),
          ),
          Expanded(
            child: _buildMethodButton(
              icon: Icons.qr_code,
              title: 'QR Kod ile Transfer',
              isSelected: _selectedTransferMethod == 1,
              onTap: () {
                setState(() {
                  _selectedTransferMethod = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodButton({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildCardSelector() {
    // Gerçek cüzdan bilgisi gösterilecek
    if (_walletError != null) {
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(_walletError!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchWallet,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
    if (_walletData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      elevation: 8,
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.accentColor,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Bakiye', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (_walletData!['balance'] ?? 0).toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 4),
                Text('₺', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Son Güncelleme: ' + (_walletData!['lastUpdated'] ?? ''), style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (_walletData!['wiban'] != null) ...[
              const SizedBox(height: 8),
              Text('WIBAN: ' + _walletData!['wiban'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildSelectedTransferMethodContent() {
    if (_selectedTransferMethod == 0) {
      // NFC Transfer
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.nfc, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'NFC ile Transfer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transfer için, cihazınızı diğer NFC destekli karta veya cihaza yaklaştırın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    } else if (_selectedTransferMethod == 1) {
      // QR Code Transfer
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildQrOption(
                icon: Icons.qr_code_scanner,
                title: 'QR Kod Tara',
                description: 'Alıcının QR kodunu tarayın',
                onTap: () async {
                  final confirm = await showModalBottomSheet<bool>(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: AppTheme.primaryColor),
                          SizedBox(height: 16),
                          Text('Kamera izni vermek istiyor musunuz?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          Text('QR kodu taramak için kamera iznine ihtiyacımız var.'),
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text('Hayır'),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text('Evet'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                  if (confirm == true) {
                    var status = await Permission.camera.status;
                    if (status.isGranted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QrScanScreen()),
                      );
                      if (result != null) {
                        if (result is Map) {
                          debugPrint('QR koddan gelen Map: ' + result.toString());
                          String? wiban = result['wiban'] ?? result['WIBAN'] ?? result['iban'] ?? result['IBAN'];
                          setState(() {
                            _receiverController.text = wiban ?? '';
                            final firstName = result['firstName'] ?? result['FIRSTNAME'] ?? '';
                            final lastName = result['lastName'] ?? result['LASTNAME'] ?? '';
                            _receiverNameController.text = (firstName + ' ' + lastName).trim();
                          });
                        } else if (result is String) {
                          setState(() {
                            _receiverController.text = result;
                            _receiverNameController.text = '';
                          });
                        }
                      }
                    } else {
                      status = await Permission.camera.request();
                      if (status.isGranted) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QrScanScreen()),
                        );
                        if (result != null) {
                          if (result is Map) {
                            debugPrint('QR koddan gelen Map: ' + result.toString());
                            String? wiban = result['wiban'] ?? result['WIBAN'] ?? result['iban'] ?? result['IBAN'];
                            setState(() {
                              _receiverController.text = wiban ?? '';
                              final firstName = result['firstName'] ?? result['FIRSTNAME'] ?? '';
                              final lastName = result['lastName'] ?? result['LASTNAME'] ?? '';
                              _receiverNameController.text = (firstName + ' ' + lastName).trim();
                            });
                          } else if (result is String) {
                            setState(() {
                              _receiverController.text = result;
                              _receiverNameController.text = '';
                            });
                          }
                        }
                      }
                      // izin verilmezse hiçbir şey yapma
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQrOption(
                icon: Icons.qr_code,
                title: 'QR Kod Oluştur',
                description: 'Transfer için QR kod oluşturun',
                onTap: () {
                  final wiban = _walletData != null ? _walletData!['wiban'] ?? '' : '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrGenerateScreen(wiban: wiban),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildQrOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchReceiverName(String input) async {
    try {
      final api = ApiService();
      final accessToken = await SecureStorageService().getAccessToken();
      final response = await api.get(
        ApiConstants.walletNameEndpoint(input),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.data != null && response.data.toString().isNotEmpty) {
        setState(() {
          _receiverName = response.data.toString();
        });
      }
    } catch (e) {
      debugPrint('Alıcı adı getirme hatası: $e');
      setState(() {
        _receiverName = null;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    String? suffixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }



  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transferi Onayla'),
        content: const Text('Bu transferi gerçekleştirmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _isLoading = true;
    });
    final api = ApiService();
    final accessToken = await SecureStorageService().getAccessToken();
    final double amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final body = {
      'receiverIdentifier': _receiverController.text.trim(),
      'receiverNameAndSurname': _receiverNameController.text.trim(),
      'amount': amount,
      'description': _noteController.text.trim(),
    };
    try {
      final response = await api.post(
        ApiConstants.transferWalletEndpoint,
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.data['success'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(response.data['message'] ?? 'Transfer başarısız.');
      }
    } catch (e) {
      _showErrorDialog('Transfer sırasında hata oluştu.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Başarılı'),
        content: const Text('Transfer işlemi başarıyla tamamlandı.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
