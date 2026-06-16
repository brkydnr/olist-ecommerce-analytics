# 🛒 E-Commerce Data Analytics & BI Pipeline

![SQL Server](https://img.shields.io/badge/SQL_Server-T--SQL-CC2927?logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python&logoColor=white)
![Dataset](https://img.shields.io/badge/Dataset-Olist_E--Commerce-150458)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## 📌 Proje Özeti (Project Overview)

Bu proje, Brezilya pazarına ait ~100.000 siparişlik gerçek e-ticaret verisi üzerinde gerçekleştirilmiş uçtan uca bir Veri Analitiği (Data Analytics) ve İş Zekası (BI) çalışmasıdır. Projenin ana odağı; operasyonel sızıntıları (lojistik gecikmeleri, satıcı iptalleri) karmaşık T-SQL sorgularıyla tespit etmek, veri şişmesini (fan-out) önleyecek veri modelleme teknikleri uygulamak ve RFM algoritması ile müşteri segmentasyonu yaparak Power BI üzerinden karar alıcılara stratejik raporlar sunmaktır.

---

## 🏗️ Veri Mimarisi ve ETL Süreci

```text
Olist E-Commerce CSV Files (8 Relational Tables)
    ↓
Data Profiling & Cleansing (T-SQL) — Null handling, Duplicate checks (HAVING COUNT > 1)
    ↓
SQL Data Warehouse (SQL Server) — Fact & Dimension relational schema (dbo.)
    ↓
Analytical SQL Pipeline — CTEs, Window Functions (NTILE, ROW_NUMBER), Aggregations
    ↓
Power BI / BI Dashboard — Executive KPI Cards, Visual Reporting
```

---

## 🛠️ Kullanılan Teknolojiler ve Teknikler

| Yetkinlik | Kullanılan Yapılar & Yaklaşımlar |
|---|---|
| **RDBMS** | Microsoft SQL Server (T-SQL), SSMS / DBeaver |
| **Gelişmiş SQL** | `CTE` (Common Table Expressions), `Window Functions` (`SUM() OVER()`, `ROW_NUMBER()`, `NTILE()`), `CAST`, `DATEDIFF` |
| **Veri Modelleme** | Satır şişmesini (Fan-out) önlemek için Deduping (Tekilleştirme) algoritmaları |
| **İş Zekası** | Power BI (Veri Görselleştirme, Slicer'lar, KPI Kartları) |

---

## 💻 Öne Çıkan SQL Geliştirmeleri (Code Highlights)

Analiz süresince yazılan ve projenin kalbini oluşturan **4 aşamalı SQL Pipeline** mimarisinden kritik kesitler:

### 1. Veri Tekilleştirme ve Gelişmiş Window Functions (Fan-out Önleme)
Birden fazla tablonun `JOIN` edilmesi sırasında oluşan satır çoğalmalarını (duplicate rows) engellemek için `ROW_NUMBER()` ve `CTE` kullanılarak güvenilir gelir ve yorum skorları hesaplanmıştır.

```sql
WITH OrderPaymentsDeduped AS (
    -- Satır şişmesini (fan-out) önlemek için sipariş ve ödeme tipi bazında tekilleştirme
    SELECT 
        order_id,
        payment_type,
        SUM(payment_value) AS total_payment_value
    FROM dbo.order_payments
    GROUP BY order_id, payment_type
)
SELECT
    op.payment_type,
    COUNT(DISTINCT op.order_id) AS total_orders,
    CAST(SUM(op.total_payment_value) AS decimal(15,2)) AS total_volume,
    -- Ödeme tipinin toplam siparişler içindeki payı (%)
    CAST(100.0 * COUNT(DISTINCT op.order_id) 
         / NULLIF(SUM(COUNT(DISTINCT op.order_id)) OVER(), 0) 
    AS decimal(10,2)) AS order_share_pct
FROM OrderPaymentsDeduped AS op
GROUP BY op.payment_type;
```

### 2. Metodolojik RFM Segmentasyonu
Müşteri sıklığının (Frequency) büyük ölçüde "1" siparişte yoğunlaştığı veri profilinde, standart `NTILE` kullanımının yapay ayrışmalar yaratacağı tespit edilmiştir. Bu yüzden *Recency* ve *Monetary* skorları `NTILE(5)` ile, *Frequency* ise mutlak eşiklerle skorlanarak analitik doğruluk artırılmıştır.

```sql
-- RFM Skorlaması Kesidi
NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
-- Frequency için NTILE yerine mutlak eşik:
CASE 
    WHEN total_orders >= 5 THEN 5
    WHEN total_orders = 4 THEN 4
    WHEN total_orders = 3 THEN 3
    WHEN total_orders = 2 THEN 2
    ELSE 1 
END AS F_Score,
NTILE(5) OVER (ORDER BY total_money_spent ASC) AS M_Score
```

---

## 📈 Stratejik İş Çıktıları (Business Insights)

SQL analizlerinden elde edilen finansal ve operasyonel bulgular:

| Insight / Bulgu | Analitik Gözlem (Data Point) | İş Etkisi & Aksiyon Önerisi |
|---|---|---|
| **🚨 Retention Krizi** | *Loyal Customers* segmentinin (cironun %20'si) Sıklık (Frequency) ortalaması `1.00`. Toplam tekrar eden müşteri ciro payı sadece **%5.67**. | Yeni müşteri edinme (CAC) yerine derhal elde tutma (Retention) programları ve çapraz satış (Cross-sell) kurguları başlatılmalıdır. |
| **📦 Lojistik ve İtibar** | *Early / On Time* teslimatlarda puan `4.30` iken, `19+ Gün` gecikmelerde (Severe Delay) puan `1.70`'e çakılmaktadır. | Kötü yorumların (1-2 yıldız) organik dönüşümü baltalamasını önlemek için kargo SLA limitlerini aşan durumlarda satıcılara penalizasyon uygulanmalıdır. |
| **💳 Ödeme Komisyonları** | Kredi kartı hacmi `1.24 Milyar` brüt ciro ile %75'lik paya sahiptir. | Kredi kartı tahsilat oranının yüksekliği bir hacim gücü olarak kullanılarak POS/Payment Gateway komisyonlarında indirime gidilmelidir. |

---

## 📊 Dashboard & Raporlama (Power BI)

Hazırlanan BI çözümü aşağıdaki panellerden oluşmaktadır:
- **Executive Summary:** Toplam Sipariş (`99.4K`), İptal Oranları (`%0.62`), Müşteri Sayıları.
- **Lojistik & Risk Paneli:** Gecikme sürelerinin (Delivery Bucket) yorum skorlarına etkisi ve `%17`lere varan iptal oranına sahip riskli satıcı profilleri.
- **Kategori Karlılığı:** `Health & Beauty` ve `Watches & Gifts` öncülüğündeki ciro kırılımları.

---

## 📂 Repository Yapısı (Repository Structure)

```text
├── sql_scripts/
│   ├── 01_Null&Duplicate_Control.sql     # Veri profilleme ve temizlik
│   ├── 02_Exploratory_Data_Analysis.sql  # Aggregations, DATEDIFF, CASE WHEN
│   ├── 03_STRATEGIC_BUSINESS_INSIGHTS.sql# Fan-out deduplication, Window Functions
│   └── 04_RFM_ANALYSIS.sql               # Segmentasyon algoritması ve metodolojisi
├── dashboard/
│   └── ecommerce_analytics.pbix          # Power BI etkileşimli raporu
├── docs/
│   └── Business_Insights_Report.pdf      # Karar alıcılar için yönetici özeti
├── README.md
```
