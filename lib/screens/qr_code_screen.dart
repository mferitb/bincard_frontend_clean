import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class QRCodeScreen extends StatefulWidget {
  final bool isScanner;
  final String? cardNumber;
  final String? cardName;

  const QRCodeScreen({
    super.key,
    this.isScanner = true,
    this.cardNumber,
    this.cardName,
  });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _flashOn = false;
  final bool _isFrontCamera = false;
  bool _isTorchOn = false;
  bool _isScanning = true;
  bool _showScanSuccess = false;
  bool _showPaymentSuccess = false;
  Timer? _scanningTimer;
  Timer? _successTimer;
  final double _scannerAreaSize = 250.0;

  // Simüle edilmiş QR kod sonucu
  final Map<String, dynamic> _scanResult = {
    'type': 'payment',
    'cardNumber': '1234 5678 9012 3456',
    'amount': 25.50,
    'timestamp': DateTime.now().toString(),
    'route': '11A - Merkez-Üniversite',
    'isValid': true,
  };

  // Kartlar listesi (aslında API'den gelecek)
  final List<Map<String, dynamic>> _cards = [
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

  int _selectedCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isScanner ? 0 : 1,
    );

    // Eğer belirli bir kart numarası iletildiyse, o kartı seç
    if (widget.cardNumber != null) {
      final index = _cards.indexWhere(
        (card) => card['number'] == widget.cardNumber,
      );
      if (index != -1) {
        _selectedCardIndex = index;
      }
    }

    if (widget.isScanner) {
      _startScanning();
    }
  }

  void _startScanning() {
    // Gerçek uygulamada, QR kod tarayıcı kütüphanesi kullanılacak
    // Burada simüle ediyoruz
    _scanningTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _isScanning = false;
        _showScanSuccess = true;
      });

      _successTimer = Timer(const Duration(seconds: 2), () {
        setState(() {
          _showScanSuccess = false;
          _showPaymentSuccess = true;
        });
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanningTimer?.cancel();
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isScanner ? 'QR Kod Tara' : 'Ödeme QR Kodu',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.isScanner)
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
              onPressed: () {
                setState(() {
                  _isTorchOn = !_isTorchOn;
                });
              },
            ),
        ],
      ),
      body: widget.isScanner ? _buildScanner() : _buildQRCode(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Simüle edilmiş kamera görüntüsü - gerçek uygulamada kamera akışı olacak
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Center(
            child: Text(
              'Kamera Önizleme',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
              ),
            ),
          ),
        ),

        // QR kod tarama alanı
        Center(
          child: Container(
            width: _scannerAreaSize,
            height: _scannerAreaSize,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Köşe işaretleri
                Positioned(top: 0, left: 0, child: _buildCorner()),
                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildCorner(topRight: true),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildCorner(bottomLeft: true),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildCorner(bottomRight: true),
                ),

                // Tarama animasyonu
                if (_isScanning) _buildScanAnimation(),
              ],
            ),
          ),
        ),

        // Talimatlar
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Text(
            _isScanning
                ? 'QR kodu çerçeve içine yerleştirin'
                : _showScanSuccess
                ? 'QR kod başarıyla okundu!'
                : 'İşlem tamamlanıyor...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
          ),
        ),

        // Başarılı tarama ekranı
        if (_showScanSuccess)
          Center(
            child: Container(
              width: _scannerAreaSize,
              height: _scannerAreaSize,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'QR Kod Okundu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Ödeme başarılı ekranı
        if (_showPaymentSuccess) _buildPaymentSuccess(),
      ],
    );
  }

  Widget _buildCorner({
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: CornerPainter(
          color: AppTheme.primaryColor,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  Widget _buildScanAnimation() {
    return AnimatedPositioned(
      duration: const Duration(seconds: 2),
      top: 0,
      left: 0,
      right: 0,
      bottom: _isScanning ? _scannerAreaSize - 4 : 0,
      curve: Curves.easeInOut,
      child: Container(height: 2, color: AppTheme.primaryColor),
    );
  }

  Widget _buildPaymentSuccess() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ödeme Başarılı',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildInfoRow('Tutar', '₺${_scanResult['amount']}'),
                _buildInfoRow('Hat', _scanResult['route']),
                _buildInfoRow(
                  'Tarih',
                  DateTime.now().toString().substring(0, 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ödeme için QR Kodu Okutun',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Container(
              width: 250,
              height: 250,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2,
                  size: 200,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Kart No: ${_scanResult['cardNumber']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tutar: ₺${_scanResult['amount']}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // QR kodu yenile
              },
              icon: const Icon(Icons.refresh),
              label: const Text('QR Kodu Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CornerPainter extends CustomPainter {
  final Color color;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  CornerPainter({
    required this.color,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    final path = Path();

    if (topRight) {
      // Sağ üst köşe
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height / 2);
      path.moveTo(size.width, 0);
      path.lineTo(size.width / 2, 0);
    } else if (bottomLeft) {
      // Sol alt köşe
      path.moveTo(0, size.height);
      path.lineTo(0, size.height / 2);
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, size.height);
    } else if (bottomRight) {
      // Sağ alt köşe
      path.moveTo(size.width, size.height);
      path.lineTo(size.width, size.height / 2);
      path.moveTo(size.width, size.height);
      path.lineTo(size.width / 2, size.height);
    } else {
      // Sol üst köşe (varsayılan)
      path.moveTo(0, 0);
      path.lineTo(0, size.height / 2);
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CornerPainter oldDelegate) => false;
}
