# 📊 Olist E-Ticaret — Stratejik Finansal Analiz Raporu

![SQL Server](https://img.shields.io/badge/SQL_Server-T--SQL-CC2927?logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-ReportLab-blue?logo=python&logoColor=white)
![Dataset](https://img.shields.io/badge/Dataset-Olist_Brazilian_E--Commerce-150458)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## 📌 Proje Özeti

Bu proje, Brezilya'nın önde gelen e-ticaret platformu **Olist**'in 2016–2018 dönemine ait ~99.441 siparişlik halka açık veri seti üzerinde gerçekleştirilen **uçtan uca finansal analiz ve iş zekası** çalışmasıdır.

**Ana Amaçlar:**
- Operasyonel başarıları teyit etmek
- Uzun vadeli kârlılığı tehdit eden yapısal riskleri tespit etmek
- RFM müşteri segmentasyonu ile yüksek değerli müşteri gruplarını belirlemek
- Somut ve uygulanabilir stratejik öneriler üretmek

**Kapsam:** Veri profilleme → Temizleme → Keşifsel Analiz → RFM Segmentasyonu → Stratejik Finansal Yorumlama

---

## 🗂️ Repository Yapısı

```
.
├── sql_scripts/
│   ├── 01_DATA_PROFILING_AND_CLEANING.sql
│   ├── 02_EXPLORATORY_DATA_ANALYSIS.sql
│   ├── 03_STRATEGIC_BUSINESS_INSIGHTS.sql
│   └── 04_RFM_ANALYSIS.sql
├── dashboard/
│   └── Olist_Dashboard.pbix          # 3 sayfalık Power BI raporu (Sales, Logistic, Quality)
├── reports/
│   └── Olist_Strategic_Financial_Analysis_Report.pdf   # Bu raporun PDF versiyonu
├── README.md
└── requirements.txt
```

---

## 🛠️ Kullanılan Teknolojiler

| Alan | Teknoloji / Yaklaşım |
|------|----------------------|
| **Veritabanı** | Microsoft SQL Server (T-SQL) |
| **Gelişmiş SQL** | CTE, Window Functions (`ROW_NUMBER()`, `NTILE()`), `NULLIF`, Fan-out önleme |
| **Veri Modelleme** | Staging tabloları (`customers_clean`), Deduplication |
| **Görselleştirme** | Power BI (3 sayfalık interaktif dashboard) |
| **Raporlama** | Python + ReportLab (Profesyonel PDF) |
| **Metodoloji** | RFM Segmentasyonu (mutlak eşik + iş mantığı) |

---

## 📈 Ana Bulgular (Veri ile Uyumlu)

### 1. Ödeme Yöntemleri Performansı
Credit Card **%75.24** sipariş payı ile baskındır ve en hızlı onay süresine (4.6 saat) sahiptir.  
Boleto **%19.46** paya sahip olmasına rağmen **33.1 saat** ortalama onay süresiyle operasyonel verimsizlik yaratmaktadır.  
Voucher iptal oranı (**%2.43**) diğer yöntemlerin 4-5 katıdır.

### 2. RFM Müşteri Segmentasyonu
Sadece `delivered` siparişler üzerinden ~93.359 unique müşteri analiz edilmiştir.

| Segment              | Müşteri Sayısı | Pay     | Avg Recency | Revenue Payı | Yorum |
|----------------------|----------------|---------|-------------|--------------|-------|
| **Loyal Customers**  | 15,356         | 16.45%  | 162 gün     | **20.78%**   | En değerli sadık grup |
| **Champions**        | 7,738          | 8.29%   | 95 gün      | **15.36%**   | En yeni + yüksek harcama |
| **Slipping Away**    | 7,318          | 7.84%   | 364 gün     | **14.80%**   | **Yüksek riskli yüksek değerli** |
| **Can't Lose Them**  | 7,099          | 7.60%   | 522 gün     | **14.22%**   | **Yüksek riskli yüksek değerli** |
| Diğer 7 Segment      | ~55,848        | ~60%    | -           | ~34.84%      | Düşük öncelikli |

**Kritik Bulgular:**
- En yüksek ciro üreten 5 segment toplam müşterilerin **%52.1**'ini oluştururken cironun **%81.5**'ini üretmektedir.
- **Slipping Away** ve **Can't Lose Them** segmentleri toplam cironun ~**%29**'unu temsil etmekte olup acil win-back gerektirmektedir.
- Tüm segmentlerde ortalama sipariş sıklığı **1.00**'dur (tekrar satın alma çok düşüktür).

### 3. Lojistik Performans ve Memnuniyet
- Teslimat başarı oranı: **%97.02**
- Erken teslimatlarda ortalama review skoru **4.30** iken, **19+ gün** gecikmede **1.70**'e düşmektedir (**%60** memnuniyet kaybı).
- Gecikme şiddeti arttıkça memnuniyet **doğrusal değil, sert bir kırılma** yaşamaktadır.

### 4. Operasyonel Riskler
- Bazı satıcılarda iptal oranı **%17.39**'a kadar çıkmaktadır (platform ortalaması **%0.63**).
- Yüksek değerli müşterilerin churn riski en büyük tehdit olarak öne çıkmaktadır.

---

## ⚠️ Veri Kalitesi Uyarısı

SQL katmanındaki parasal değerler (`payment_value`, `price`, `freight_value`) gerçek değerin yaklaşık **100 katı** olarak hesaplanmıştır.  
Bu durum, veri yükleme sırasında ondalık ayıracı hatasından kaynaklanmaktadır.

**Dashboard** görsellerinde yer alan **R$15.86M** toplam ciro rakamı gerçekçi değerdir.  
Bu raporda tüm parasal karşılaştırmalar **yüzde ve oran** bazında yapılmış, mutlak değerler ise dashboard ile uyumlu şekilde referans verilmiştir.

---

## 🎯 Stratejik Öneriler (Öncelik Sırasıyla)

| Öncelik | Aksiyon | Hedef Segment / Alan | Beklenen Etki |
|---------|---------|----------------------|---------------|
| **1** | Win-Back Kampanyası | Slipping Away + Can't Lose Them | ~%29 ciro kaybını önleme |
| **2** | Lojistik SLA İyileştirmesi + Otomatik Bildirim | Ağır gecikme riskli siparişler | Review skoru ve NPS artışı |
| **3** | Satıcı Risk Yönetimi (%3 Kritik İptal Eşiği) | Yüksek iptal oranlı satıcılar | Operasyonel maliyet düşüşü |
| **4** | Tiered Loyalty Programı | Champions + Loyal Customers | Uzun vadeli CLV artışı |
| **5** | Veri Kalitesi Düzeltmesi | Staging / ETL katmanı | Raporlama güvenilirliği |

---

## 📂 Dosyalar

- `Olist_Strategic_Financial_Analysis_Report.pdf` → **Ana rapor** (görsel + veri uyumlu hibrit versiyon)
- `sql_scripts/` → 4 modüllük T-SQL pipeline
- `dashboard/` → Power BI raporu (Sales, Logistic, Quality)

---

## 🚀 Nasıl Çalıştırılır

1. Olist veri setini Kaggle'dan indirin.
2. CSV dosyalarını SQL Server'a `dbo` şeması altında yükleyin.
3. `sql_scripts` klasöründeki scriptleri **sırayla** çalıştırın (01 → 04).
4. Power BI dosyasını açın ve veri kaynağını güncelleyin.
5. PDF raporunu inceleyin.

---
