[README (1).md](https://github.com/user-attachments/files/29004694/README.1.md)
# E-Commerce Financial & Operational Analytics 

Brezilya pazarına ait geniş çaplı bir e-ticaret veri setinin operasyonel, müşteri ve finansal boyutlarda SQL kullanılarak derinlemesine analiz edildiği ve stratejik iş içgörülerine dönüştürüldüğü veri analitiği projesidir.

# Proje Amacı

Bu proje, platformun müşteri yaşam boyu değerini (LTV) ve operasyonel maliyetlerini etkileyen ana unsurları (lojistik performans, müşteri sadakati, satıcı iptal oranları) finansal bir bakış açısıyla ölçmek; RFM analizi ile müşteri segmentasyonunu gerçekleştirerek pazarlama bütçesi tahsisini (CAC optimizasyonu) veri odaklı stratejilerle yeniden şekillendirmek amacıyla yapılmıştır.

# Veri Seti

- **Veri Kaynağı:** Olist E-Commerce Dataset (Brezilya pazarı)
- **Tablo Sayısı:** 6-8 ilişkisel tablo
- **Temel Tablolar:** Siparişler, Sipariş Kalemleri, Ödemeler, Müşteri Yorumları, Müşteriler, Satıcılar.
- **İlişkiler:** Sipariş ve müşteri odaklı (order_id, customer_id, seller_id) One-to-Many ilişkiler.
- **Kullanılan Ana Alanlar:** order_status, review_score, payment_type, delivery_delay_days, recency, frequency, monetary.

# Kullanılan Teknolojiler

- PostgreSQL / SQL Server
- T-SQL / pgSQL
- DBeaver / SSMS
- Power BI (Veri Görselleştirme ve Dashboarding)
- Python (Veri ön işleme ve dokümantasyon)

# Yapılan Analizler

- **Veri Temizleme:** Eksik ve hatalı teslimat verilerinin ayıklanması.
- **JOIN İşlemleri:** Müşteri, sipariş ve ödeme verilerinin birleştirilmesi.
- **Aggregate Functions:** Toplam ciro, ortalama sepet tutarı ve iptal oranlarının hesaplanması.
- **CASE WHEN:** Teslimat gecikme sürelerine göre sınıflandırma (Delivery Bucket - Early, On Time, Mild/Moderate/Severe Delay).
- **Window Functions:** Kategori ve satıcı bazlı ciro sıralamaları (Ranking).
- **RFM Analizi:** Recency, Frequency, Monetary metriklerinin hesaplanarak müşterilerin 11 farklı segmente ayrılması.
- **Segmentasyon:** Müşteri kârlılık profillerinin (Champions, Loyal Customers, At Risk vb.) çıkarılması.
- **KPI Hesaplamaları:** Müşteri elde tutma (Retention), sipariş iptal oranı, tekrar eden müşteri ciro payı hesabı.

# Dashboard Özeti

- **Kartlar (KPI'lar):** Toplam Sipariş Sayısı (99.441), Toplam Gelir (1.58 Milyar), Ortalama Puan, Platform İptal Oranı (%0.62).
- **Grafikler:** - Kategori bazlı brüt gelir dağılımı (Health & Beauty, Watches & Gifts liderliğinde).
  - Teslimat süresi grupları (Delivery Bucket) ve ortalama müşteri puanı ilişkisi.
  - RFM segmentlerine göre gelir payı dağılımı (Örn: Loyal Customers %20.78 gelir payı).
- **Filtreler ve Slicerlar:** Zaman çizelgesi, Sipariş Durumu, Teslimat Gecikme Durumu, Ödeme Türü (Credit Card, Boleto vb.).

# Projede Öğrenilenler

- Finansal metriklerin (Toplam Gelir, Ciro Payı, İptal Maliyetleri) SQL sorguları ile operasyonel metriklerle (Gecikme Süresi) ilişkilendirilmesi.
- Müşteri bazlı RFM analizinin gerçek hayat verisine uygulanarak, müşteri sadakatinin sayısal olarak (Frequency = 1.00) ifşa edilmesi.
- Yüksek iptal oranına sahip outlier satıcıların tespitinde SQL'in gücünün kavranması ve analitik bulguların finansal raporlamaya dönüştürülmesi.

# Sonuç

Müşteri ediniminde büyük bir hacme (yaklaşık 1.58 Milyar ciro) ulaşılmış olsa da, şirketin büyümesinin tek seferlik alımlara dayandığı ve sadakat döngüsünün kurulamadığı finansal olarak kanıtlanmıştır. Operasyonel tarafta lojistik aksaklıkların marka algısına ve finansal sürdürülebilirliğe verdiği zarar sayısal olarak ortaya konmuş, karar alıcılara net ve veriye dayalı aksiyon alanları sunulmuştur.
