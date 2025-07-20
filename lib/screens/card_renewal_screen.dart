import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CardRenewalScreen extends StatefulWidget {
  const CardRenewalScreen({super.key});

  @override
  State<CardRenewalScreen> createState() => _CardRenewalScreenState();
}

class _CardRenewalScreenState extends State<CardRenewalScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  int _currentStep = 0;

  // Form değerleri
  String _cardNumber = '';
  String _identityNumber = '';
  DateTime? _expiryDate;
  String _paymentMethod = 'Kredi/Banka Kartı';
  bool _acceptTerms = false;

  // Örnek kart türleri
  final List<Map<String, dynamic>> _cardTypes = [
    {
      'id': 'standard',
      'name': 'Standart Kart',
      'description': 'Herkes için geçerli standart ulaşım kartı',
      'fee': 50.0,
      'icon': Icons.credit_card,
      'color': AppTheme.primaryColor,
    },
    {
      'id': 'student',
      'name': 'Öğrenci Kartı',
      'description': 'İndirimli öğrenci ulaşım kartı',
      'fee': 30.0,
      'icon': Icons.school,
      'color': AppTheme.infoColor,
    },
    {
      'id': 'senior',
      'name': '65+ Kart',
      'description': '65 yaş üstü vatandaşlar için ulaşım kartı',
      'fee': 20.0,
      'icon': Icons.accessible,
      'color': AppTheme.accentColor,
    },
    {
      'id': 'disabled',
      'name': 'Engelli Kartı',
      'description': 'Engelli vatandaşlar için ulaşım kartı',
      'fee': 10.0,
      'icon': Icons.accessible_forward,
      'color': AppTheme.secondaryColor,
    },
  ];

  // Seçilen kart türü
  String _selectedCardTypeId = 'standard';

  Map<String, dynamic> get _selectedCardType {
    return _cardTypes.firstWhere(
      (type) => type['id'] == _selectedCardTypeId,
      orElse: () => _cardTypes.first,
    );
  }

  // Ödeme yöntemleri
  final List<String> _paymentMethods = [
    'Kredi/Banka Kartı',
    'Havale/EFT',
    'Mobil Ödeme',
    'Nakit Ödeme',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Kart Vizesi Yeniletme',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _continue,
        onStepCancel: _cancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    _currentStep == 3
                        ? _isProcessing
                            ? 'İşleniyor...'
                            : 'Tamamla'
                        : 'Devam Et',
                  ),
                ),
                if (_currentStep > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(
                        'Geri',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Kart Seçimi'),
            content: _buildCardTypeSelection(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Kart Bilgileri'),
            content: _buildCardInfoForm(),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Ödeme Yöntemi'),
            content: _buildPaymentMethodSelection(),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Onay'),
            content: _buildConfirmation(),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCardTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yenilemek istediğiniz kart türünü seçin:',
          style: TextStyle(fontSize: 16, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cardTypes.length,
          itemBuilder: (context, index) {
            final cardType = _cardTypes[index];
            final isSelected = cardType['id'] == _selectedCardTypeId;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCardTypeId = cardType['id'];
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cardType['color'].withOpacity(0.2),
                        child: Icon(cardType['icon'], color: cardType['color']),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cardType['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cardType['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vize Ücreti: ₺${cardType['fee'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: cardType['id'],
                        groupValue: _selectedCardTypeId,
                        onChanged: (value) {
                          setState(() {
                            _selectedCardTypeId = value!;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCardInfoForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kart bilgilerinizi girin:',
            style: TextStyle(fontSize: 16, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Kart Numarası',
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(Icons.credit_card, color: AppTheme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kart numarası gerekli';
              }
              if (value.length < 16) {
                return 'Geçerli bir kart numarası girin';
              }
              return null;
            },
            onChanged: (value) {
              _cardNumber = value;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'T.C. Kimlik Numarası',
              hintText: '12345678901',
              prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'T.C. Kimlik numarası gerekli';
              }
              if (value.length != 11) {
                return 'Geçerli bir T.C. Kimlik numarası girin';
              }
              return null;
            },
            onChanged: (value) {
              _identityNumber = value;
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppTheme.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _expiryDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Yeni Vize Süresi',
                prefixIcon: Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _expiryDate == null
                    ? 'Vize süresi seçin'
                    : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                style: TextStyle(
                  color:
                      _expiryDate == null
                          ? AppTheme.textSecondaryColor
                          : AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ödeme yöntemini seçin:',
          style: TextStyle(fontSize: 16, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vize Ücreti',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${_selectedCardType['fee'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    final isSelected = method == _paymentMethod;

                    IconData icon;
                    switch (index) {
                      case 0:
                        icon = Icons.credit_card;
                        break;
                      case 1:
                        icon = Icons.account_balance;
                        break;
                      case 2:
                        icon = Icons.phone_android;
                        break;
                      case 3:
                        icon = Icons.attach_money;
                        break;
                      default:
                        icon = Icons.payment;
                    }

                    return RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(
                            icon,
                            color:
                                isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(method),
                        ],
                      ),
                      value: method,
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sipariş Özeti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Kart Türü', _selectedCardType['name']),
                _buildSummaryRow(
                  'Kart Numarası',
                  _cardNumber.isEmpty
                      ? '-'
                      : _cardNumber.replaceRange(4, 12, ' **** **** '),
                ),
                _buildSummaryRow(
                  'T.C. Kimlik No',
                  _identityNumber.isEmpty
                      ? '-'
                      : '*****${_identityNumber.substring(5)}',
                ),
                _buildSummaryRow(
                  'Vize Süresi',
                  _expiryDate == null
                      ? '-'
                      : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                ),
                _buildSummaryRow('Ödeme Yöntemi', _paymentMethod),
                const Divider(),
                _buildSummaryRow(
                  'Toplam Tutar',
                  '₺${_selectedCardType['fee'].toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _acceptTerms,
              onChanged: (value) {
                setState(() {
                  _acceptTerms = value!;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _acceptTerms = !_acceptTerms;
                  });
                },
                child: Text(
                  'Kullanım koşullarını ve gizlilik politikasını okudum, kabul ediyorum.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!_acceptTerms && _isProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Devam etmek için koşulları kabul etmelisiniz.',
              style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _continue() {
    if (_currentStep == 1) {
      if (_formKey.currentState!.validate() && _expiryDate != null) {
        setState(() {
          _currentStep += 1;
        });
      }
    } else if (_currentStep == 3) {
      _submitRenewal();
    } else {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _cancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Future<void> _submitRenewal() async {
    if (!_acceptTerms) {
      setState(() {
        _isProcessing = true;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Burada gerçek bir API çağrısı olacak
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successColor),
                const SizedBox(width: 8),
                const Text('İşlem Başarılı'),
              ],
            ),
            content: const Text(
              'Kart vizesi yenileme talebiniz alınmıştır. İşlem tamamlandığında bilgilendirileceksiniz.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }
}
