import 'package:flutter/material.dart';
import '../models/contract_model.dart';
import '../models/contract_type.dart';
import '../services/contract_service.dart';

class SingleContractModal extends StatelessWidget {
  final ContractDTO contract;

  const SingleContractModal({
    Key? key,
    required this.contract,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF6C5CE7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      contract.title ?? 'Sözleşme',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Modal Body
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sözleşme Bilgileri
                      if (contract.version != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Sürüm: ${contract.version}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (contract.createdAt != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Tarih: ${contract.createdAt.toString().split('T')[0]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Sözleşme İçeriği
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          contract.content ?? 'İçerik bulunamadı',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Modal Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Kapat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, ContractDTO contract) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => SingleContractModal(contract: contract),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<void> showContractById(BuildContext context, int contractId) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Contract service'den sözleşmeyi getir
      final contractService = ContractService();
      final contract = await contractService.getContractById(contractId);

      // Loading'i kapat
      Navigator.of(context).pop();

      // Sözleşme modalını göster
      SingleContractModal.show(context, contract);
    } catch (e) {
      // Loading'i kapat
      Navigator.of(context).pop();

      // Hata mesajını göster
      _showError(context, 'Sözleşme yüklenemedi: ${e.toString()}');
    }
  }

  static Future<void> showContractByType(BuildContext context, ContractType contractType) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Contract service'den sözleşmeyi getir
      final contractService = ContractService();
      final contract = await contractService.getLatestContractByType(contractType);

      // Loading'i kapat
      Navigator.of(context).pop();

      // Sözleşme modalını göster
      SingleContractModal.show(context, contract);
    } catch (e) {
      // Loading'i kapat
      Navigator.of(context).pop();

      // Hata mesajını göster
      _showError(context, '${contractType.displayName} yüklenemedi: ${e.toString()}');
    }
  }

  static Future<void> showMembershipContract(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Contract service'den sözleşmeyi getir
      final contractService = ContractService();
      final contract = await contractService.getMembershipContract();

      // Loading'i kapat
      Navigator.of(context).pop();

      // Sözleşme modalını göster
      SingleContractModal.show(context, contract);
    } catch (e) {
      // Loading'i kapat
      Navigator.of(context).pop();

      // Hata mesajını göster
      _showError(context, 'Üyelik Sözleşmesi yüklenemedi: ${e.toString()}');
    }
  }

  static Future<void> showKvkkIllumination(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Contract service'den sözleşmeyi getir
      final contractService = ContractService();
      final contract = await contractService.getKvkkIllumination();

      // Loading'i kapat
      Navigator.of(context).pop();

      // Sözleşme modalını göster
      SingleContractModal.show(context, contract);
    } catch (e) {
      // Loading'i kapat
      Navigator.of(context).pop();

      // Hata mesajını göster
      _showError(context, 'KVKK Aydınlatma Metni yüklenemedi: ${e.toString()}');
    }
  }

  static Future<void> showDataProcessingConsent(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Contract service'den sözleşmeyi getir
      final contractService = ContractService();
      final contract = await contractService.getDataProcessingConsent();

      // Loading'i kapat
      Navigator.of(context).pop();

      // Sözleşme modalını göster
      SingleContractModal.show(context, contract);
    } catch (e) {
      // Loading'i kapat
      Navigator.of(context).pop();

      // Hata mesajını göster
      _showError(context, 'Veri İşleme İzni yüklenemedi: ${e.toString()}');
    }
  }

  static Future<void> showPrivacyPolicy(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Contract service'den sözleşmeyi getir
      final contractService = ContractService();
      final contract = await contractService.getPrivacyPolicy();

      // Loading'i kapat
      Navigator.of(context).pop();

      // Sözleşme modalını göster
      SingleContractModal.show(context, contract);
    } catch (e) {
      // Loading'i kapat
      Navigator.of(context).pop();

      // Hata mesajını göster
      _showError(context, 'Gizlilik Politikası yüklenemedi: ${e.toString()}');
    }
  }

  static Future<void> showTermsOfUse(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Contract service'den sözleşmeyi getir
      final contractService = ContractService();
      final contract = await contractService.getTermsOfUse();

      // Loading'i kapat
      Navigator.of(context).pop();

      // Sözleşme modalını göster
      SingleContractModal.show(context, contract);
    } catch (e) {
      // Loading'i kapat
      Navigator.of(context).pop();

      // Hata mesajını göster
      _showError(context, 'Kullanım Koşulları yüklenemedi: ${e.toString()}');
    }
  }
}
