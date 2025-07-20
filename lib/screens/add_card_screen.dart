import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saveCard = true;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
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
          'Kart Ekle',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardPreview(),
                const SizedBox(height: 32),
                _buildCardNumberField(),
                const SizedBox(height: 16),
                _buildCardHolderNameField(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildExpiryDateField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCvvField()),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSaveCardOption(),
                const SizedBox(height: 40),
                _buildAddCardButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.accentColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Kart süslemeleri
          Positioned(
            top: 20,
            right: 20,
            child: Icon(
              FontAwesomeIcons.wifi,
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Icon(
              FontAwesomeIcons.ccVisa,
              color: Colors.white.withOpacity(0.9),
              size: 40,
            ),
          ),
          // Kart içeriği
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şehir Kartı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _formatCardNumber(
                    _cardNumberController.text.isEmpty
                        ? 'XXXX XXXX XXXX XXXX'
                        : _cardNumberController.text,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KART SAHİBİ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _cardHolderNameController.text.isEmpty
                              ? 'AD SOYAD'
                              : _cardHolderNameController.text.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GEÇERLİLİK',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _expiryDateController.text.isEmpty
                              ? 'MM/YY'
                              : _expiryDateController.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CVV',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _cvvController.text.isEmpty ? '***' : '***',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String cardNumber) {
    if (cardNumber.length < 16) {
      return cardNumber;
    }
    return '${cardNumber.substring(0, 4)} ${cardNumber.substring(4, 8)} ${cardNumber.substring(8, 12)} ${cardNumber.substring(12, 16)}';
  }

  Widget _buildCardNumberField() {
    return _buildTextField(
      controller: _cardNumberController,
      label: 'Kart Numarası',
      hint: '1234 5678 9012 3456',
      icon: Icons.credit_card,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
        _CardNumberFormatter(),
      ],
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kart numarası gerekli';
        }
        if (value.replaceAll(' ', '').length < 16) {
          return 'Geçerli bir kart numarası girin';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildCardHolderNameField() {
    return _buildTextField(
      controller: _cardHolderNameController,
      label: 'Kart Üzerindeki İsim',
      hint: 'Ad Soyad',
      icon: Icons.person,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kart sahibinin adı gerekli';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildExpiryDateField() {
    return _buildTextField(
      controller: _expiryDateController,
      label: 'Son Kullanma Tarihi',
      hint: 'MM/YY',
      icon: Icons.calendar_today,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        _ExpiryDateFormatter(),
      ],
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Son kullanma tarihi gerekli';
        }
        if (value.length < 5) {
          return 'Geçerli bir tarih girin';
        }

        final parts = value.split('/');
        if (parts.length != 2) {
          return 'Geçerli bir tarih girin';
        }

        final month = int.tryParse(parts[0]);
        if (month == null || month < 1 || month > 12) {
          return 'Geçerli bir ay girin (1-12)';
        }

        return null;
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildCvvField() {
    return _buildTextField(
      controller: _cvvController,
      label: 'CVV',
      hint: '123',
      icon: Icons.security,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      keyboardType: TextInputType.number,
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'CVV gerekli';
        }
        if (value.length < 3) {
          return 'Geçerli bir CVV girin';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
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
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
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
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSaveCardOption() {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kartı Kaydet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gelecekte daha hızlı ödeme yapmak için kartınızı kaydedin',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _saveCard,
            onChanged: (value) {
              setState(() {
                _saveCard = value;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    return Container(
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
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Kart kaydetme işlemini gerçekleştir
            Navigator.pop(context);
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
          'Kartı Ekle',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      if ((i + 1) % 4 == 0 && i != digitsOnly.length - 1) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.isEmpty) {
      return newValue;
    }

    final digitsOnly = newText.replaceAll('/', '');
    if (digitsOnly.length > 4) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      if (i == 1 && i != digitsOnly.length - 1) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
