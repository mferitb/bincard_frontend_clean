import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  final List<Map<String, dynamic>> _cards = [
    {
      'cardNumber': '5312 **** **** 3456',
      'cardHolderName': 'Ahmet Yılmaz',
      'expiryDate': '12/25',
      'isActive': true,
      'type': 'visa',
      'color': AppTheme.blueGradient,
    },
    {
      'cardNumber': '4728 **** **** 9012',
      'cardHolderName': 'Ahmet Yılmaz',
      'expiryDate': '08/24',
      'isActive': true,
      'type': 'mastercard',
      'color': AppTheme.greenGradient,
    },
    {
      'cardNumber': '3782 **** **** 1234',
      'cardHolderName': 'Ahmet Yılmaz',
      'expiryDate': '05/26',
      'isActive': false,
      'type': 'amex',
      'color': AppTheme.purpleGradient,
    },
  ];

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
          'Kayıtlı Kartlarım',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _cards.isEmpty ? _buildEmptyState() : _buildCardsList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Kart ekleme sayfasına yönlendir
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.creditCard,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Kayıtlı Kart Bulunamadı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hızlı ödeme yapmak için kart ekleyebilirsiniz',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Kart ekleme sayfasına yönlendir
            },
            icon: const Icon(Icons.add),
            label: const Text('Kart Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _buildCardItem(
          cardNumber: card['cardNumber'],
          cardHolderName: card['cardHolderName'],
          expiryDate: card['expiryDate'],
          isActive: card['isActive'],
          type: card['type'],
          color: card['color'],
          onCardTap: () {
            // Kart detaylarını göster
            _showCardOptions(context, index);
          },
        );
      },
    );
  }

  Widget _buildCardItem({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required bool isActive,
    required String type,
    required List<Color> color,
    required VoidCallback onCardTap,
  }) {
    IconData cardIcon;
    switch (type) {
      case 'mastercard':
        cardIcon = FontAwesomeIcons.ccMastercard;
        break;
      case 'amex':
        cardIcon = FontAwesomeIcons.ccAmex;
        break;
      case 'visa':
      default:
        cardIcon = FontAwesomeIcons.ccVisa;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onCardTap,
        child: Stack(
          children: [
            Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: color,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.solidCreditCard,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Şehir Kartı',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              isActive ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cardNumber,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              cardHolderName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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
                              expiryDate,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          cardIcon,
                          color: Colors.white.withOpacity(0.9),
                          size: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Icon(
                  Icons.wifi,
                  color: Colors.white.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardOptions(BuildContext context, int index) {
    final card = _cards[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Kart İşlemleri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionItem(
                  icon: Icons.credit_card,
                  title: 'Kart Detayları',
                  onTap: () {
                    Navigator.pop(context);
                    // Kart detaylarına git
                  },
                ),
                const Divider(),
                _buildOptionItem(
                  icon: Icons.edit,
                  title: 'Kartı Düzenle',
                  onTap: () {
                    Navigator.pop(context);
                    // Kart düzenleme sayfasına git
                  },
                ),
                const Divider(),
                card['isActive']
                    ? _buildOptionItem(
                      icon: Icons.block,
                      title: 'Kartı Devre Dışı Bırak',
                      onTap: () {
                        setState(() {
                          _cards[index]['isActive'] = false;
                        });
                        Navigator.pop(context);
                      },
                      color: Colors.orange,
                    )
                    : _buildOptionItem(
                      icon: Icons.check_circle,
                      title: 'Kartı Aktifleştir',
                      onTap: () {
                        setState(() {
                          _cards[index]['isActive'] = true;
                        });
                        Navigator.pop(context);
                      },
                      color: Colors.green,
                    ),
                const Divider(),
                _buildOptionItem(
                  icon: Icons.delete_outline,
                  title: 'Kartı Sil',
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, index);
                  },
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: AppTheme.textPrimaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color ?? AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Kartı Sil'),
            content: const Text(
              'Bu kartı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'İptal',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _cards.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sil'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }
}
