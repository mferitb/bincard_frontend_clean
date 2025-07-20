import 'package:flutter/material.dart';
import '../models/payment_point_model.dart';
import '../services/payment_point_service.dart';

class PaymentPointDetailScreen extends StatefulWidget {
  final int paymentPointId;
  const PaymentPointDetailScreen({Key? key, required this.paymentPointId}) : super(key: key);

  @override
  State<PaymentPointDetailScreen> createState() => _PaymentPointDetailScreenState();
}

class _PaymentPointDetailScreenState extends State<PaymentPointDetailScreen> {
  late Future<PaymentPoint> _paymentPointFuture;

  @override
  void initState() {
    super.initState();
    _paymentPointFuture = PaymentPointService().getPaymentPointById(widget.paymentPointId);
  }

  Widget _buildStatusChip(bool active) {
    return Chip(
      label: Text(active ? 'Aktif' : 'Pasif', style: const TextStyle(color: Colors.white)),
      backgroundColor: active ? Colors.green : Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'CASH':
        return Icons.attach_money;
      case 'CREDIT_CARD':
        return Icons.credit_card;
      case 'DEBIT_CARD':
        return Icons.account_balance_wallet;
      case 'QR_CODE':
        return Icons.qr_code;
      default:
        return Icons.payment;
    }
  }

  Color _paymentMethodChipColor(BuildContext context, String method) {
    switch (method) {
      case 'CASH':
        return Colors.green;
      case 'CREDIT_CARD':
        return Colors.blue;
      case 'DEBIT_CARD':
        return Colors.redAccent.shade100;
      case 'QR_CODE':
        return Theme.of(context).primaryColor;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Noktası Detayı'),
      ),
      body: FutureBuilder<PaymentPoint>(
        future: _paymentPointFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: \\${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Detay bulunamadı.'));
          }
          final point = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (point.photos.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: point.photos.length,
                        separatorBuilder: (context, i) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final photo = point.photos[i];
                          String url = '';
                          if (photo is String) {
                            url = photo;
                          } else if (photo is Map) {
                            final dynamic val = photo['imageUrl'];
                            if (val is String) {
                              url = val;
                            }
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              url,
                              width: 260,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                width: 260,
                                height: 180,
                                child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.place, color: Colors.blueGrey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point.address.street + ', ' + point.address.district + ', ' + point.address.city,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.markunread_mailbox, color: Colors.blueGrey[700]),
                      const SizedBox(width: 8),
                      Text('Posta Kodu: ' + point.address.postalCode),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blueGrey[700]),
                      const SizedBox(width: 8),
                      Text(point.contactNumber, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blueGrey[700]),
                      const SizedBox(width: 8),
                      Text('Çalışma Saatleri: ' + point.workingHours),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Ödeme Yöntemleri:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    children: point.paymentMethods.map((m) => Chip(
                      avatar: Icon(_paymentMethodIcon(m), size: 18, color: Colors.white),
                      label: Text(m, style: const TextStyle(color: Colors.white)),
                      backgroundColor: _paymentMethodChipColor(context, m),
                    )).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text('Açıklama:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(point.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 18),
                  Text('Oluşturulma: ' + point.createdAt.toString().substring(0, 16)),
                  Text('Güncellenme: ' + point.lastUpdated.toString().substring(0, 16)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 