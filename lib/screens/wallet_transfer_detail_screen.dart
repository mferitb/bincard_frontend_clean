import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class WalletTransferDetailScreen extends StatefulWidget {
  final int transferId;
  const WalletTransferDetailScreen({super.key, required this.transferId});

  @override
  State<WalletTransferDetailScreen> createState() => _WalletTransferDetailScreenState();
}

class _WalletTransferDetailScreenState extends State<WalletTransferDetailScreen> {
  Map<String, dynamic>? _transfer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ApiService();
      final accessToken = await SecureStorageService().getAccessToken();
      final response = await api.get(
        '/wallet/transfer/${widget.transferId}',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        setState(() { _transfer = response.data['data']; });
      } else {
        setState(() { _error = response.data['message'] ?? 'Detay alınamadı'; });
      }
    } catch (e) {
      setState(() { _error = 'Detay alınamadı'; });
    } finally {
      setState(() { _isLoading = false; });
    }
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
        title: const Text('Transfer Detayı'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _transfer == null
                  ? const Center(child: Text('Detay bulunamadı.'))
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.swap_horiz, color: AppTheme.primaryColor, size: 32),
                                  const SizedBox(width: 12),
                                  Text('Transfer #${_transfer!['id']}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildDetailRow('Tutar', '${_transfer!['amount']} ₺', bold: true),
                              const SizedBox(height: 8),
                              _buildDetailRow('Açıklama', _transfer!['description'] ?? '-'),
                              const SizedBox(height: 8),
                              _buildDetailRow('Durum', _transfer!['status'] ?? '-'),
                              const SizedBox(height: 8),
                              _buildDetailRow('Başlatan Kullanıcı', (_transfer!['initiatedByUserId'] ?? '-').toString()),
                              const SizedBox(height: 8),
                              _buildDetailRow('Gönderen Cüzdan', (_transfer!['senderWalletId'] ?? '-').toString()),
                              const SizedBox(height: 8),
                              _buildDetailRow('Alıcı Cüzdan', (_transfer!['receiverWalletId'] ?? '-').toString()),
                              const SizedBox(height: 8),
                              _buildDetailRow('Başlatılma', _formatDate(_transfer!['initiatedAt'])),
                              const SizedBox(height: 8),
                              _buildDetailRow('Tamamlanma', _formatDate(_transfer!['completedAt'])),
                              if (_transfer!['cancellationReason'] != null) ...[
                                const SizedBox(height: 8),
                                _buildDetailRow('İptal Nedeni', _transfer!['cancellationReason']),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 16))),
      ],
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }
} 