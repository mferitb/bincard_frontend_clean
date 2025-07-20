import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class VirtualCardScreen extends StatefulWidget {
  const VirtualCardScreen({super.key});

  @override
  State<VirtualCardScreen> createState() => _VirtualCardScreenState();
}

class _VirtualCardScreenState extends State<VirtualCardScreen> {
  bool _hasVirtualCard = false;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  // Sanal kart bilgileri
  final Map<String, dynamic> _virtualCard = {
    'id': 'VC123456789',
    'number': '4546 **** **** 7890',
    'balance': 150.75,
    'expiryDate': DateTime.now().add(const Duration(days: 365)),
    'isActive': true,
    'type': 'Standard',
    'lastUsed': DateTime.now().subtract(const Duration(days: 2)),
    'transactions': [
      {
        'id': 'T12345',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'amount': -25.50,
        'description': 'Otobüs Ücreti - 11A',
        'type': 'transport',
      },
      {
        'id': 'T12346',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'amount': -15.75,
        'description': 'Metro Geçişi',
        'type': 'transport',
      },
      {
        'id': 'T12347',
        'date': DateTime.now().subtract(const Duration(days: 10)),
        'amount': 200.00,
        'description': 'Bakiye Yükleme',
        'type': 'topup',
      },
      {
        'id': 'T12348',
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'amount': -8.00,
        'description': 'Tramvay Geçişi',
        'type': 'transport',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadVirtualCardData();
  }

  // Gerçek uygulamada API'den veri çekilecek
  Future<void> _loadVirtualCardData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _hasVirtualCard = true; // Örnek için true yapıyoruz
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Sanal Kart'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVirtualCardData,
          ),
        ],
      ),
      body: _hasVirtualCard ? _buildCardDetails() : _buildNoCardView(),
      floatingActionButton:
          _hasVirtualCard
              ? FloatingActionButton(
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.add),
                onPressed: () {
                  _showTopUpDialog(context);
                },
              )
              : null,
    );
  }

  Widget _buildNoCardView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz sanal kartınız bulunmuyor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sanal kart ile toplu taşıma araçlarında\nkolayca ödeme yapabilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _showPurchaseCardDialog(context);
            },
            icon: const Icon(Icons.add_card),
            label: const Text('Sanal Kart Satın Al'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVirtualCardWidget(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildCardInfo(),
          const SizedBox(height: 24),
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildVirtualCardWidget() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
        child: Stack(
          children: [
            // Kart Arka Plan Deseni
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.circle,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Icon(
                Icons.circle,
                size: 180,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // Kart İçeriği
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sanal Şehir Kartı',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _virtualCard['isActive']
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                            _virtualCard['isActive']
                                ? Colors.greenAccent
                                : Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _virtualCard['number'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                          const Text(
                            'BAKİYE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(_virtualCard['balance']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SON KULLANIM',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MM/yy',
                            ).format(_virtualCard['expiryDate']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.contactless,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.add,
          label: 'Bakiye Yükle',
          onTap: () {
            _showTopUpDialog(context);
          },
        ),
        _buildActionButton(
          icon: Icons.qr_code,
          label: 'QR Kod',
          onTap: () {
            _showQRCodeDialog(context);
          },
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Paylaş',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kart bilgileri paylaşıldı')),
            );
          },
        ),
        _buildActionButton(
          icon: _virtualCard['isActive'] ? Icons.pause : Icons.play_arrow,
          label: _virtualCard['isActive'] ? 'Durdur' : 'Aktifleştir',
          onTap: () {
            setState(() {
              _virtualCard['isActive'] = !_virtualCard['isActive'];
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
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

  Widget _buildCardInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kart Bilgileri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Kart Numarası', _virtualCard['number']),
            _buildInfoRow('Kart Türü', _virtualCard['type']),
            _buildInfoRow(
              'Son Kullanma Tarihi',
              DateFormat('dd/MM/yyyy').format(_virtualCard['expiryDate']),
            ),
            _buildInfoRow(
              'Son Kullanım',
              DateFormat('dd/MM/yyyy HH:mm').format(_virtualCard['lastUsed']),
            ),
            _buildInfoRow(
              'Durum',
              _virtualCard['isActive'] ? 'Aktif' : 'Pasif',
              valueColor:
                  _virtualCard['isActive']
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'İşlem Geçmişi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                // Tüm işlem geçmişini göster
              },
              child: Text(
                'Tümünü Gör',
                style: TextStyle(fontSize: 14, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _virtualCard['transactions'].length,
          itemBuilder: (context, index) {
            final transaction = _virtualCard['transactions'][index];
            final bool isIncome = transaction['amount'] > 0;

            IconData icon;
            Color iconColor;

            switch (transaction['type']) {
              case 'transport':
                icon = Icons.directions_bus;
                iconColor = AppTheme.primaryColor;
                break;
              case 'topup':
                icon = Icons.account_balance_wallet;
                iconColor = AppTheme.successColor;
                break;
              default:
                icon = Icons.payment;
                iconColor = AppTheme.accentColor;
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor),
              ),
              title: Text(
                transaction['description'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(transaction['date']),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              trailing: Text(
                '${isIncome ? '+' : ''}${_currencyFormat.format(transaction['amount'])}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color:
                      isIncome
                          ? AppTheme.successColor
                          : AppTheme.textPrimaryColor,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showPurchaseCardDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController identityController = TextEditingController();
    bool acceptTerms = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.credit_card_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sanal Kart Satın Al'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sanal kart satın almak için aşağıdaki bilgileri doldurun:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Ad Soyad',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: identityController,
                        decoration: InputDecoration(
                          labelText: 'T.C. Kimlik No',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sanal kart ücreti: ₺25,00',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                acceptTerms = value!;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  acceptTerms = !acceptTerms;
                                });
                              },
                              child: Text(
                                'Kullanım koşullarını ve gizlilik politikasını kabul ediyorum',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'İptal',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        acceptTerms &&
                                nameController.text.isNotEmpty &&
                                identityController.text.isNotEmpty
                            ? () {
                              Navigator.pop(context);
                              _showPurchaseSuccess(context);
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: const Text('Satın Al'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showPurchaseSuccess(BuildContext context) {
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
              'Sanal kart satın alma işleminiz başarıyla tamamlandı. Kartınız hesabınıza tanımlandı.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _hasVirtualCard = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('Bakiye Yükle'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yüklemek istediğiniz tutarı girin:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Tutar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: '₺',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Hızlı Seçim:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children:
                      [50, 100, 200].map((amount) {
                        return InkWell(
                          onTap: () {
                            amountController.text = amount.toString();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '₺$amount',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'İptal',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    Navigator.pop(context);
                    _showPaymentMethodsDialog(context, amount);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Devam Et'),
              ),
            ],
          ),
    );
  }

  void _showPaymentMethodsDialog(BuildContext context, double amount) {
    final List<Map<String, dynamic>> paymentMethods = [
      {
        'id': 'credit_card',
        'name': 'Kredi/Banka Kartı',
        'icon': Icons.credit_card,
      },
      {'id': 'transfer', 'name': 'Havale/EFT', 'icon': Icons.account_balance},
      {'id': 'mobile', 'name': 'Mobil Ödeme', 'icon': Icons.phone_android},
    ];

    String selectedMethod = paymentMethods.first['id'];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.payment, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Ödeme Yöntemi'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yüklenecek Tutar: ${_currencyFormat.format(amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ödeme yöntemini seçin:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...paymentMethods.map((method) {
                      return RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(
                              method['icon'],
                              color:
                                  method['id'] == selectedMethod
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(method['name']),
                          ],
                        ),
                        value: method['id'],
                        groupValue: selectedMethod,
                        onChanged: (value) {
                          setState(() {
                            selectedMethod = value!;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'İptal',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _processPayment(context, amount, selectedMethod);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Ödeme Yap'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _processPayment(BuildContext context, double amount, String method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Ödeme işleniyor...'),
              ],
            ),
          ),
    );

    // Simüle edilmiş ödeme işlemi
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pop(context); // Yükleniyor dialogunu kapat

      setState(() {
        _virtualCard['balance'] += amount;
        _virtualCard['transactions'].insert(0, {
          'id': 'T${DateTime.now().millisecondsSinceEpoch}',
          'date': DateTime.now(),
          'amount': amount,
          'description': 'Bakiye Yükleme',
          'type': 'topup',
        });
      });

      // Başarı mesajı
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
              content: Text(
                'Kartınıza ${_currencyFormat.format(amount)} tutarında bakiye yüklendi.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Tamam'),
                ),
              ],
            ),
      );
    });
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.qr_code, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('QR Kod'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bu QR kodu okutarak ödeme yapabilirsiniz',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_2,
                      size: 150,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kart No: ${_virtualCard['number']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bakiye: ${_currencyFormat.format(_virtualCard['balance'])}',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Kapat',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('QR kod paylaşıldı')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Paylaş'),
              ),
            ],
          ),
    );
  }
}
