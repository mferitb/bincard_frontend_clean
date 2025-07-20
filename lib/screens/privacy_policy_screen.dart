import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Gizlilik Politikası',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLastUpdatedInfo(),
              const SizedBox(height: 24),
              _buildPolicySection(
                title: '1. Topladığımız Bilgiler',
                content: '''
Şehir Kart uygulaması, size hizmet verebilmek için aşağıdaki bilgileri toplayabilir:

• Kişisel Bilgiler: Ad, soyad, e-posta adresi, telefon numarası, doğum tarihi ve adres gibi bilgiler.

• Ödeme Bilgileri: Kredi kartı bilgileri, banka hesap bilgileri veya diğer finansal bilgiler. Bu bilgiler, güvenli ödeme işlemcilerimiz tarafından işlenir ve saklanır.

• Konum Bilgileri: Uygulama kullanımınız sırasında, yakınınızdaki durakları ve rotaları gösterebilmek için konum bilgilerinizi toplayabiliriz.

• Cihaz Bilgileri: Cihaz modeli, işletim sistemi, benzersiz cihaz tanımlayıcıları, IP adresi ve mobil ağ bilgileri.

• Kullanım Verileri: Uygulama özelliklerini nasıl kullandığınız, ziyaret ettiğiniz sayfalar ve etkileşimde bulunduğunuz içerikler hakkında bilgiler.
''',
              ),
              _buildPolicySection(
                title: '2. Bilgileri Kullanma Amacımız',
                content: '''
Topladığımız bilgileri aşağıdaki amaçlarla kullanırız:

• Hizmet Sağlama: Hesabınızı oluşturmak, bakiye yüklemek, kart işlemlerini gerçekleştirmek ve müşteri desteği sağlamak.

• Hizmet İyileştirme: Uygulamanın kullanımını analiz etmek, hataları tespit etmek ve yeni özellikler geliştirmek.

• Kişiselleştirme: Size özel teklifler, içerik ve reklamlar sunmak.

• İletişim: Hizmet güncellemeleri, güvenlik uyarıları ve promosyonlar hakkında sizinle iletişim kurmak.

• Güvenlik: Hesabınızı korumak, dolandırıcılık faaliyetlerini önlemek ve uygulamanın güvenliğini sağlamak.
''',
              ),
              _buildPolicySection(
                title: '3. Bilgi Paylaşımı',
                content: '''
Bilgilerinizi aşağıdaki durumlarda üçüncü taraflarla paylaşabiliriz:

• Hizmet Sağlayıcılar: Ödeme işleme, veri analizi, e-posta gönderimi, hosting hizmetleri ve müşteri hizmetleri gibi hizmetleri sağlayan güvenilir üçüncü taraf şirketler.

• İş Ortakları: Size ilgili ürünler, hizmetler veya promosyonlar sunmak için iş ortaklarımızla bilgi paylaşabiliriz.

• Yasal Gereklilikler: Yasal bir yükümlülüğe uymak, Şehir Kart'ın haklarını veya mülkiyetini korumak, acil durumlarda kişisel güvenliği korumak veya yasa uygulayıcı makamların taleplerine yanıt vermek için bilgileri paylaşabiliriz.

• İşletme Transferleri: Şirket birleşmesi, satın alma veya varlık satışı durumunda, bilgileriniz aktarılan varlıklar arasında olabilir.

Kişisel bilgilerinizi, açık izniniz olmadan üçüncü taraf pazarlamacılara satmayız veya kiralamayız.
''',
              ),
              _buildPolicySection(
                title: '4. Veri Güvenliği',
                content: '''
Bilgilerinizi korumak için uygun teknik ve organizasyonel önlemler alıyoruz. Bu önlemler arasında şifreleme, güvenli sunucular, düzenli güvenlik değerlendirmeleri ve personel eğitimi bulunmaktadır.

Ancak, internet üzerinden hiçbir veri iletimi veya elektronik depolama yöntemi %100 güvenli değildir. Bu nedenle, bilgilerinizin mutlak güvenliğini garanti edemeyiz.

Hesap güvenliğinizi korumak için, güçlü bir şifre seçmenizi ve bu şifreyi başka hesaplarınız için kullanmamanızı öneririz. Ayrıca, hesabınızda şüpheli bir aktivite fark ederseniz, lütfen hemen bizimle iletişime geçin.
''',
              ),
              _buildPolicySection(
                title: '5. Çerezler ve İzleme Teknolojileri',
                content: '''
Şehir Kart uygulaması, deneyiminizi geliştirmek ve analiz yapmak için çerezler ve benzer izleme teknolojileri kullanabilir. Bu teknolojiler, oturum bilgilerini hatırlamak, kullanım istatistiklerini toplamak ve içeriği kişiselleştirmek için kullanılır.

Çerezleri cihazınızdan silebilir veya tarayıcı ayarlarınızı değiştirerek çerezleri reddedebilirsiniz, ancak bu, uygulamanın bazı özelliklerinin düzgün çalışmamasına neden olabilir.

Üçüncü taraf analiz sağlayıcıları (örneğin Google Analytics), uygulama kullanımınızı izlemek ve analiz etmek için kendi çerezlerini kullanabilir. Bu üçüncü tarafların bilgi toplama uygulamaları kendi gizlilik politikalarına tabidir.
''',
              ),
              _buildPolicySection(
                title: '6. Veri Saklama',
                content: '''
Kişisel bilgilerinizi, hizmetlerimizi sağlamak için gerekli olduğu sürece veya yasal yükümlülüklerimizi yerine getirmek için gerekli olduğu sürece saklarız.

Hesabınızı silmeyi seçerseniz, kişisel bilgilerinizi sistemlerimizden sileriz veya anonimleştiririz. Ancak, yasal yükümlülüklerimizi yerine getirmek, anlaşmazlıkları çözmek ve sözleşmelerimizi uygulamak için gerekli olan bilgileri saklayabiliriz.

Belirli verileri, istatistiksel analiz, dolandırıcılık önleme veya hizmet geliştirme amacıyla, anonim veya toplu formda saklayabiliriz.
''',
              ),
              _buildPolicySection(
                title: '7. Çocukların Gizliliği',
                content: '''
Şehir Kart uygulaması, 18 yaşın altındaki çocuklara yönelik değildir. Bilerek 18 yaşın altındaki çocuklardan kişisel bilgi toplamayız.

18 yaşın altındaki bir çocuktan kişisel bilgi topladığımızı fark edersek, bu bilgileri en kısa sürede silmek için adımlar atarız. Bir ebeveyn veya vasi olarak, çocuğunuzun bize kişisel bilgi sağladığına inanıyorsanız, lütfen bizimle iletişime geçin.

13-18 yaş arası gençler, ebeveyn veya vasi gözetiminde uygulamayı kullanabilir. Bu durumda, ebeveyn veya vasi, çocuğun bilgilerinin toplanması ve kullanılması için izin vermiş sayılır.
''',
              ),
              _buildPolicySection(
                title: '8. Haklarınız',
                content: '''
Kişisel verilerinizle ilgili olarak aşağıdaki haklara sahipsiniz:

• Erişim Hakkı: Hakkınızda hangi bilgileri tuttuğumuzu öğrenme hakkı.

• Düzeltme Hakkı: Yanlış veya eksik bilgilerinizin düzeltilmesini isteme hakkı.

• Silme Hakkı: Belirli koşullar altında kişisel verilerinizin silinmesini isteme hakkı.

• İşlemeyi Kısıtlama Hakkı: Belirli koşullar altında kişisel verilerinizin işlenmesini kısıtlama hakkı.

• Veri Taşınabilirliği Hakkı: Verilerinizi yapılandırılmış, yaygın olarak kullanılan ve makine tarafından okunabilir bir formatta alma hakkı.

• İtiraz Hakkı: Meşru menfaatlerimize dayalı olarak verilerinizi işlememize itiraz etme hakkı.

Bu haklarınızı kullanmak için, lütfen aşağıdaki iletişim bilgilerini kullanarak bizimle iletişime geçin.
''',
              ),
              _buildPolicySection(
                title: '9. Politika Değişiklikleri',
                content: '''
Bu Gizlilik Politikası'nı zaman zaman güncelleyebiliriz. Önemli değişiklikler yaptığımızda, uygulama içinde bir bildirim yayınlayacak veya size doğrudan bir bildirim göndereceğiz.

Bu politikadaki değişiklikleri düzenli olarak gözden geçirmenizi öneririz. Bu politikayı değiştirdikten sonra uygulamayı kullanmaya devam etmeniz, değiştirilmiş politikayı kabul ettiğiniz anlamına gelir.
''',
              ),
              _buildPolicySection(
                title: '10. İletişim',
                content: '''
Bu Gizlilik Politikası hakkında sorularınız veya endişeleriniz varsa, lütfen bizimle iletişime geçin:

Şehir Kart
E-posta: privacy@sehirkart.com.tr
Adres: Cumhuriyet Cad. No:123, 34000, İstanbul, Türkiye
Telefon: (0212) 123 45 67
''',
              ),
              const SizedBox(height: 32),
              _buildAcceptButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.infoColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.infoColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Son Güncelleme Tarihi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1 Haziran 2025',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
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
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Anladım ve Kabul Ediyorum',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 