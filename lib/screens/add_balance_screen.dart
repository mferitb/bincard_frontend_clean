import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/nfc_service.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import '../routes.dart';
import 'package:card_scanner/card_scanner.dart';

class AddBalanceScreen extends StatefulWidget {
  const AddBalanceScreen({super.key});

  @override
  State<AddBalanceScreen> createState() => _AddBalanceScreenState();
}

class _AddBalanceStep {
  static const int amount = 0;
  static const int paymentMethod = 1;
  static const int cardInfo = 2;
}

class _AddBalanceScreenState extends State<AddBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int _selectedPaymentMethodIndex = 0;
  int _selectedAmountIndex = -1;
  final List<double> _predefinedAmounts = [50, 100, 150, 200, 250];

  // Kredi kartı bilgileri
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  // NFC servisi
  final NfcService _nfcService = NfcService();
  bool _isNfcReading = false;
  int _currentStep = 0;
  bool _isLoading = false;

  // Tam ve küsurat için controllerlar
  final TextEditingController _amountWholeController = TextEditingController();
  final TextEditingController _amountFractionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  // NFC kullanılabilirliğini kontrol et
  Future<void> _checkNfcAvailability() async {
    final isAvailable = await _nfcService.isAvailable();
    if (mounted) {
      setState(() {
        // NFC durumunu güncelleyebilirsiniz
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountWholeController.dispose();
    _amountFractionController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
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
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
        ),
        title: Text(
          'Bakiye Yükle',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Stack(
        children: [
          // Sağ alt ileri/onayla butonu
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                if (_currentStep < 2) {
                  setState(() {
                    _currentStep++;
                  });
                } else if (_currentStep == 2 && !_isLoading) {
                  _handleTopUp();
                }
              },
              label: Text(_currentStep < 2 ? 'İleri' : 'Onayla'),
              icon: Icon(Icons.arrow_forward),
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
          // Sol alt geri butonu
          Positioned(
            bottom: 16,
            left: 42,
            child: FloatingActionButton.extended(
              onPressed: () {
                if (_currentStep == 0) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                } else {
                  setState(() {
                    _currentStep--;
                  });
                }
              },
              label: const Text('Geri'),
              icon: const Icon(Icons.arrow_back),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepContent(),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (_isNfcReading)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Kredi kartınızı telefonun arkasına yaklaştırın...',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: AppTheme.primaryColor,
                          onPressed: _cancelNfcReading,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case _AddBalanceStep.amount:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Özel tutar alanı üstte, ortalanmış ve spacing ile
            const SizedBox(height: 12),
            Center(child: _buildCustomAmountField()),
            const SizedBox(height: 24),
            // Modern başlık ve açıklama
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Yüklenecek Tutarı Seç',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Hazır tutarlardan birini seçebilir veya yukarıdan özel tutar girebilirsin.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Modern hazır tutar kartları alt alta
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _predefinedAmounts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final bool isSelected = index == _selectedAmountIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmountIndex = index;
                      _amountWholeController.text = _predefinedAmounts[index].toInt().toString();
                      _amountFractionController.text = (_predefinedAmounts[index] % 1 * 100).toInt().toString().padLeft(2, '0');
                      _updateAmountController();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _predefinedAmounts[index].toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TL',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white70 : AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      case _AddBalanceStep.paymentMethod:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
              child: Text(
                'Ödeme Yöntemi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            _buildPaymentMethodSelection(onlyCard: true),
          ],
        );
      case _AddBalanceStep.cardInfo:
        return _buildCreditCardForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPaymentMethodSelection({bool onlyCard = false}) {
    // Sadece kredi/banka kartı aktif olacak şekilde
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.credit_card, color: AppTheme.primaryColor),
          title: const Text('Kredi/Banka Kartı'),
          trailing: Radio<int>(
            value: 0,
            groupValue: _selectedPaymentMethodIndex,
            onChanged: (val) {
              setState(() {
                _selectedPaymentMethodIndex = 0;
              });
            },
          ),
        ),
        if (!onlyCard)
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: Colors.grey),
            title: const Text('Cüzdan'),
            trailing: Radio<int>(
              value: 1,
              groupValue: _selectedPaymentMethodIndex,
              onChanged: null, // Disabled
            ),
            enabled: false,
            subtitle: const Text('Şu an aktif değil', style: TextStyle(color: Colors.grey)),
          ),
        if (!onlyCard)
          ListTile(
            leading: Icon(Icons.qr_code, color: Colors.grey),
            title: const Text('QR ile Ödeme'),
            trailing: Radio<int>(
              value: 2,
              groupValue: _selectedPaymentMethodIndex,
              onChanged: null, // Disabled
            ),
            enabled: false,
            subtitle: const Text('Şu an aktif değil', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildCardSelection() {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              FontAwesomeIcons.creditCard,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şehir Kartım',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '5312 **** **** 3456',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildPredefinedAmounts() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _predefinedAmounts.length,
      itemBuilder: (context, index) {
        final bool isSelected = index == _selectedAmountIndex;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedAmountIndex = index;
              _amountController.text = _predefinedAmounts[index].toString();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: Text(
                '${_predefinedAmounts[index].toStringAsFixed(0)} ₺',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAmountField() {
    final double maxInputWidth = MediaQuery.of(context).size.width * 0.5;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Tam kısım
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 80, maxWidth: maxInputWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: IntrinsicWidth(
              child: TextFormField(
                controller: _amountWholeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                  filled: false,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                maxLength: 6,
                scrollPadding: EdgeInsets.zero,
                enableInteractiveSelection: true,
                autofocus: false,
                onTap: () {
                  _amountWholeController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _amountWholeController.text.length),
                  );
                },
                validator: (value) {
                  if ((value == null || value.isEmpty) && (_amountFractionController.text.isEmpty)) {
                    return 'Lütfen bir tutar girin';
                  }
                  return null;
                },
                onChanged: (value) {
                  _updateAmountController();
                },
              ),
            ),
          ),
        ),
        // Virgül
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(',', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ),
        // Küsurat
        SizedBox(
          width: 40,
          child: TextFormField(
            controller: _amountFractionController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '00',
              isDense: true,
              contentPadding: EdgeInsets.zero,
              fillColor: Colors.transparent,
              filled: false,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                return 'Geçerli bir kuruş girin';
              }
              return null;
            },
            onChanged: (value) {
              _updateAmountController();
            },
          ),
        ),
        // TL
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text('TL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  void _updateAmountController() {
    final whole = _amountWholeController.text;
    final fraction = _amountFractionController.text;
    String value = whole;
    if (fraction.isNotEmpty) {
      value += "," + fraction.padRight(2, '0');
    }
    _amountController.text = value;
    setState(() {
      _selectedAmountIndex = -1;
    });
  }

  Widget _buildPaymentMethodItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
  }) {
    final bool isSelected = index == _selectedPaymentMethodIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethodIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Radio(
              value: index,
              groupValue: _selectedPaymentMethodIndex,
              activeColor: AppTheme.primaryColor,
              onChanged: (int? value) {
                setState(() {
                  _selectedPaymentMethodIndex = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Kredi kartı formu
  Widget _buildCreditCardForm() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kart Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _startCardScan,
                icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                label: Text(
                  'Kamera ile Oku',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'Kart Numarası',
              prefixIcon: Icon(
                FontAwesomeIcons.creditCard,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kart numarası gerekli';
              }
              final cleanValue = value.replaceAll(' ', '');
              if (cleanValue.length < 16) {
                return 'Geçerli bir kart numarası girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardHolderController,
            decoration: InputDecoration(
              labelText: 'Kart Üzerindeki İsim',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
            // validator kaldırıldı, zorunlu değil
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cardExpiryController,
                  decoration: InputDecoration(
                    labelText: 'Son Kullanma Tarihi',
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.date_range),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _CardExpiryFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Son kullanma tarihi gerekli';
                    }
                    if (value.length < 5) {
                      return 'Geçerli bir tarih girin';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _cardCvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: const Icon(Icons.security),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'CVV gerekli';
                    }
                    if (value.length < 3) {
                      return 'Geçerli CVV girin';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAndConfirmButton() {
    return Column(
      children: [
        Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam Tutar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                _amountController.text.isEmpty
                    ? '0.00 ₺'
                    : '${_amountController.text} ₺',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed:
                _isNfcReading
                    ? null
                    : () {
                      if (_formKey.currentState!.validate()) {
                        // Ödeme işlemini gerçekleştir
                        _showPaymentSuccessDialog();
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ödemeyi Tamamla',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // NFC ile kart okuma fonksiyonunu kaldır, yerine kart tarama fonksiyonu ekle
  Future<void> _startCardScan() async {
    final cardDetails = await CardScanner.scanCard(
      scanOptions: CardScanOptions(
        scanCardHolderName: true,
        scanExpiryDate: true,
      ),
    );
    if (cardDetails != null) {
      setState(() {
        _cardNumberController.text = cardDetails.cardNumber ?? '';
        _cardHolderController.text = cardDetails.cardHolderName ?? '';
        _cardExpiryController.text = cardDetails.expiryDate ?? '';
      });
    }
  }

  // NFC okuma işlemini iptal et
  void _cancelNfcReading() {
    _nfcService.stopNfcSession();
    setState(() {
      _isNfcReading = false;
    });
  }

  // Ödeme başarılı diyaloğu
  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('İşlem Başarılı'),
              ],
            ),
            content: const Text(
              'Ödeme işleminiz başarıyla tamamlandı. Kartınıza bakiye yüklendi.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Diyaloğu kapat
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false); // Ana sayfaya yönlendir
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleTopUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final api = ApiService();
      // api.setupTokenInterceptor(); // Artık gerek yok, manuel header ekleyeceğiz
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final cardExpiry = _cardExpiryController.text;
      final cardCvc = _cardCvvController.text;
      final body = {
        'amount': amount,
        'cardNumber': cardNumber,
        'cardExpiry': cardExpiry,
        'cardCvc': cardCvc,
        'platform': 'MOBILE',
      };
      // accessToken'ı al
      final accessToken = await SecureStorageService().getAccessToken();
      final response = await api.post(
        ApiConstants.topUpWalletEndpoint,
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        final html = response.data['data'];
        if (mounted) {
          late final WebViewController controller;
          controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(NavigationDelegate(
              onNavigationRequest: (navigation) {
                final url = navigation.url.toLowerCase();
                if (url.contains('success')) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onPageFinished: (url) async {
                try {
                  final html = await controller.runJavaScriptReturningResult(
                    "document.body.innerText || document.body.textContent"
                  );
                  if (html != null && html.toString().contains('Yükleme başarılı')) {
                    await Future.delayed(const Duration(seconds: 1));
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                  }
                } catch (_) {}
              },
            ))
            ..loadHtmlString(html);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('3D Secure')),
                body: WebViewWidget(controller: controller),
              ),
            ),
          );
        }
      } else {
        _showError(response.data['message'] ?? 'İşlem başarısız.');
      }
    } catch (e) {
      _showError('İşlem sırasında hata oluştu.');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
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

// Kart numarası formatı için input formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Son kullanma tarihi formatı için input formatter
class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
