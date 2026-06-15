/* ============================================================   
   04_RFM_ANALYSIS (Güncellenmiş - Frequency Dahil Tam Kod)

   METODOLOJİ NOTU: 
   Olist verisinde müşteri başına sipariş sayısı büyük ölçüde tek siparişte 
   yoğunlaştığı için NTILE tabanlı Frequency skorlaması yapay segment 
   ayrışmaları üretebilir. Bu nedenle Frequency, göreli dilimleme yerine 
   mutlak eşiklerle skorlanmış; böylece dağılım korunmuş, ancak Frequency’nin 
   segment ayrıştırıcı gücü doğal olarak sınırlı kalmıştır.
============================================================ */

WITH CustomerBase AS (
    SELECT 
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id)      AS total_orders, -- FREQUENCY İÇİN EKLENDİ
        SUM(p.payment_value)            AS total_money_spent          
    FROM dbo.customers AS c
    INNER JOIN dbo.orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN dbo.order_payments AS p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered' 
    GROUP BY c.customer_unique_id
),
AnalysisDate AS (
    SELECT MAX(order_purchase_timestamp) AS max_date FROM dbo.orders
),
RawRFM AS (
    SELECT 
        cb.customer_unique_id,
        DATEDIFF(DAY, cb.last_order_date, ad.max_date) AS Recency,
        cb.total_orders                                AS Frequency, -- RAW FREQUENCY
        cb.total_money_spent                           AS Monetary
    FROM CustomerBase AS cb
    CROSS JOIN AnalysisDate AS ad
),
RFMScores AS (
    SELECT
        customer_unique_id,
        Recency,
        Frequency,
        Monetary,
        -- Recency: küçük gün farkı = daha yeni = daha iyi
        CASE
            WHEN Recency <= 141 THEN 5
            WHEN Recency <= 226 THEN 4
            WHEN Recency <= 317 THEN 3
            WHEN Recency <= 431 THEN 2
            ELSE 1
        END AS R_Score,
        -- Frequency: yüksek sipariş = daha iyi
        CASE
            WHEN Frequency >= 5 THEN 5
            WHEN Frequency = 4  THEN 4
            WHEN Frequency = 3  THEN 3
            WHEN Frequency = 2  THEN 2
            ELSE 1
        END AS F_Score,
        -- Monetary: yüksek harcama = daha iyi
        CASE
            WHEN Monetary > 20855 THEN 5
            WHEN Monetary > 13270 THEN 4
            WHEN Monetary > 8736  THEN 3
            WHEN Monetary > 5526  THEN 2
            ELSE 1
        END AS M_Score
    FROM RawRFM
), -- İŞTE HATAYA SEBEP OLAN EKSİK VİRGÜL BURADAYDI!
RFMSegments AS (
    SELECT
        customer_unique_id,
        Recency, Frequency, Monetary, 
        R_Score, F_Score, M_Score,
        -- Mevcut segmentasyon kurallarınız R ve M üzerineydi, o kısmı bozmadım.
        -- İsterseniz ileride F_Score'u da bu mantığa (AND F_Score >= 3 gibi) ekleyebilirsiniz.
        CASE
            WHEN R_Score = 5 AND M_Score >= 4 THEN 'Champions'
            WHEN R_Score = 5 AND M_Score = 3  THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND M_Score >= 3 THEN 'Loyal Customers'
            WHEN R_Score = 5 AND M_Score <= 2  THEN 'New Customers'
            WHEN R_Score = 4 AND M_Score <= 2  THEN 'Promising'
            WHEN R_Score >= 3 AND M_Score >= 3 THEN 'Potential Loyalists'
            WHEN R_Score = 3 AND M_Score <= 2  THEN 'Need Attention'
            WHEN R_Score = 2 AND M_Score >= 4  THEN 'Slipping Away'
            WHEN R_Score = 2 AND M_Score >= 3  THEN 'At Risk'
            WHEN R_Score = 2 AND M_Score <= 2  THEN 'Hibernating'
            WHEN R_Score = 1 AND M_Score >= 4  THEN 'Cant Lose Them'
            WHEN R_Score = 1 AND M_Score >= 3  THEN 'At Risk'
            WHEN R_Score = 1 AND M_Score <= 2  THEN 'Lost'
        END AS Segment
    FROM RFMScores
)
-- 02. SEGMENT SUMMARY
SELECT
    Segment,
    COUNT(*)                             AS Total_Customers,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()
        AS decimal(10,2))                AS Customer_Share_Pct,
    AVG(Recency)                         AS Avg_Recency_Days,
    CAST(AVG(Frequency) AS decimal(10,2))AS Avg_Frequency, -- FREQUENCY ÖZET TABLOYA EKLENDİ
    CAST(AVG(Monetary)  AS decimal(15,2)) AS Avg_Monetary,
    CAST(SUM(Monetary)  AS decimal(15,2)) AS Total_Segment_Revenue,
    CAST(100.0 * SUM(Monetary) / SUM(SUM(Monetary)) OVER ()
        AS decimal(10,2))                AS Revenue_Share_Pct
FROM RFMSegments
GROUP BY Segment
ORDER BY Total_Customers DESC;
