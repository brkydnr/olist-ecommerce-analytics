/* ============================================================

   03_STRATEGIC_BUSINESS_INSIGHTS

   ============================================================ */



-- 01. REVIEW SCORE VS ORDER REVENUE

WITH PaymentSummary AS (

    SELECT

        order_id,

        SUM(payment_value) AS total_payment

    FROM dbo.order_payments

    GROUP BY order_id

),

ReviewDeduped AS (

    SELECT

        order_id,

        review_score,

        ROW_NUMBER() OVER (

            PARTITION BY order_id

            ORDER BY review_creation_date DESC, review_id DESC

        ) AS rn

    FROM dbo.order_reviews

)

SELECT

    r.review_score,

    CASE r.review_score

        WHEN 5 THEN 'Excellent'

        WHEN 4 THEN 'Very Good'

        WHEN 3 THEN 'Good'

        WHEN 2 THEN 'Bad'

        WHEN 1 THEN 'Very Bad'

        ELSE 'Unknown'

    END AS rating,

    COUNT(DISTINCT o.order_id) AS no_orders,

    CAST(SUM(ps.total_payment) AS decimal(15,2)) AS total_revenue,

    CAST(AVG(ps.total_payment) AS decimal(10,2)) AS avg_revenue

FROM dbo.orders AS o

INNER JOIN ReviewDeduped AS r

    ON o.order_id = r.order_id

   AND r.rn = 1

INNER JOIN PaymentSummary AS ps

    ON o.order_id = ps.order_id

WHERE o.order_status <> 'canceled'

  AND o.order_approved_at IS NOT NULL

GROUP BY r.review_score

ORDER BY r.review_score DESC;

GO



-- 02. DELIVERY DELAY VS REVIEW SCORE

WITH ReviewDeduped AS (

    SELECT

        order_id,

        review_score,

        ROW_NUMBER() OVER (

            PARTITION BY order_id

            ORDER BY review_creation_date DESC, review_id DESC

        ) AS rn

    FROM dbo.order_reviews

),

DelayBase AS (

    SELECT

        o.order_id,

        rd.review_score,

        DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delay_days

    FROM dbo.orders AS o

    INNER JOIN ReviewDeduped AS rd

        ON o.order_id = rd.order_id

       AND rd.rn = 1

    WHERE o.order_status = 'delivered'

      AND o.order_delivered_customer_date IS NOT NULL

      AND o.order_estimated_delivery_date IS NOT NULL

),

Bucketed AS (

    SELECT

        review_score,

        delay_days,

        CASE

            WHEN delay_days <= -3 THEN 'Early (3+ days)'

            WHEN delay_days BETWEEN -2 AND 0 THEN 'On Time'

            WHEN delay_days BETWEEN 1 AND 3 THEN 'Mild Delay'

            WHEN delay_days BETWEEN 4 AND 7 THEN 'Moderate Delay'

            ELSE 'Severe Delay'

        END AS delivery_bucket,

        CASE

            WHEN delay_days <= -3 THEN 1

            WHEN delay_days BETWEEN -2 AND 0 THEN 2

            WHEN delay_days BETWEEN 1 AND 3 THEN 3

            WHEN delay_days BETWEEN 4 AND 7 THEN 4

            ELSE 5

        END AS bucket_sort

    FROM DelayBase

)

SELECT

    delivery_bucket,

    COUNT(*) AS orders,

    CAST(AVG(CAST(review_score AS decimal(10,2))) AS decimal(10,2)) AS avg_review_score,

    CAST(AVG(CASE WHEN delay_days > 0 THEN CAST(delay_days AS decimal(10,2)) END) AS decimal(10,2)) AS avg_delay_days_only_for_delayed_orders

FROM Bucketed

GROUP BY delivery_bucket, bucket_sort

ORDER BY bucket_sort;

GO



-- 03. REPEAT CUSTOMER REVENUE SHARE

WITH customer_order_counts AS (

    SELECT

        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders_cnt

    FROM dbo.orders AS o

    INNER JOIN dbo.customers_clean AS c

        ON o.customer_id = c.customer_id

    WHERE o.order_status <> 'canceled'

    GROUP BY c.customer_unique_id

),

order_revenue AS (

    SELECT

        order_id,

        SUM(payment_value) AS order_payment

    FROM dbo.order_payments

    GROUP BY order_id

),

valid_orders AS (

    SELECT

        o.order_id,

        c.customer_unique_id,

        coc.total_orders_cnt,

        COALESCE(orv.order_payment, 0) AS order_payment

    FROM dbo.orders AS o

    INNER JOIN dbo.customers_clean AS c

        ON o.customer_id = c.customer_id

    INNER JOIN customer_order_counts AS coc

        ON c.customer_unique_id = coc.customer_unique_id

    LEFT JOIN order_revenue AS orv

        ON o.order_id = orv.order_id

    WHERE o.order_status <> 'canceled'

)

SELECT

    COUNT(DISTINCT CASE WHEN total_orders_cnt > 1 THEN customer_unique_id END) AS repeat_customers,

    ROUND(

        100.0 * SUM(CASE WHEN total_orders_cnt > 1 THEN order_payment ELSE 0 END)

        / NULLIF(SUM(order_payment), 0), 2

    ) AS repeat_revenue_share_pct

FROM valid_orders;

GO



-- 04. SELLER CANCELLATION RATE VS PLATFORM AVERAGE

WITH seller_orders AS (

    SELECT DISTINCT

        oi.seller_id,

        o.order_id,

        o.order_status

    FROM dbo.order_itemst AS oi

    INNER JOIN dbo.orders AS o

        ON oi.order_id = o.order_id

),

platform_cancel_rate AS (

    SELECT

        100.0 * COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) / NULLIF(COUNT(*), 0) AS avg_cancel_rate_pct

    FROM dbo.orders

)

SELECT

    p.avg_cancel_rate_pct AS platform_avg_cancel_rate_pct,

    so.seller_id,

    COUNT(*) AS total_orders,

    COUNT(CASE WHEN so.order_status = 'canceled' THEN 1 END) AS canceled_orders,

    CAST(100.0 * COUNT(CASE WHEN so.order_status = 'canceled' THEN 1 END) / NULLIF(COUNT(*), 0) AS decimal(10,2)) AS seller_cancel_rate_pct

FROM seller_orders AS so

CROSS JOIN platform_cancel_rate AS p

GROUP BY

    p.avg_cancel_rate_pct,

    so.seller_id

HAVING COUNT(*) > 20

ORDER BY seller_cancel_rate_pct DESC, total_orders DESC;

GO



-- 05. ACTIVE SELLERS BY MONTH-COVERAGE

WITH seller_months AS (

    SELECT

        oi.seller_id,

        COUNT(DISTINCT DATEFROMPARTS(YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp), 1)) AS active_months

    FROM dbo.order_itemst AS oi

    INNER JOIN dbo.orders AS o

        ON oi.order_id = o.order_id

    WHERE o.order_status <> 'canceled'

    GROUP BY oi.seller_id

)

SELECT

    CASE

        WHEN active_months >= 6 THEN '6+ months'

        WHEN active_months >= 3 THEN '3-5 months'

        ELSE 'Under 3 months'

    END AS activity_bucket,

    COUNT(*) AS sellers

FROM seller_months

GROUP BY

    CASE

        WHEN active_months >= 6 THEN '6+ months'

        WHEN active_months >= 3 THEN '3-5 months'

        ELSE 'Under 3 months'

    END

ORDER BY sellers DESC;

GO



-- 06. ACTIVE SELLERS OVER TIME

WITH seller_year_months AS (

    SELECT

        YEAR(o.order_purchase_timestamp) AS [year],

        oi.seller_id,

        COUNT(DISTINCT DATEFROMPARTS(YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp), 1)) AS active_months_in_year

    FROM dbo.order_itemst AS oi

    INNER JOIN dbo.orders AS o

        ON oi.order_id = o.order_id

    WHERE o.order_status <> 'canceled'

    GROUP BY

        YEAR(o.order_purchase_timestamp),

        oi.seller_id

)

SELECT

    [year],

    COUNT(*) AS active_sellers

FROM seller_year_months

WHERE active_months_in_year >= 3

GROUP BY [year]

ORDER BY [year];

GO



-- 07. CATEGORY X PAYMENT MIX BY ORDER COUNT

WITH order_category AS (

    SELECT DISTINCT

        oi.order_id,

        COALESCE(t.product_category_name_english, 'unknown_category') AS category

    FROM dbo.order_itemst AS oi

    INNER JOIN dbo.products AS pr

        ON oi.product_id = pr.product_id

    LEFT JOIN dbo.product_category_name_translation AS t

        ON LOWER(pr.product_category_name) = LOWER(t.product_category_name)

),

valid_pay AS (

    SELECT

        p.order_id,

        p.payment_type

    FROM dbo.order_payments AS p

    INNER JOIN dbo.orders AS o

        ON p.order_id = o.order_id

    WHERE o.order_status <> 'canceled'

      AND o.order_approved_at IS NOT NULL

),

category_payment AS (

    SELECT

        oc.category,

        vp.payment_type,

        COUNT(DISTINCT vp.order_id) AS orders

    FROM valid_pay AS vp

    INNER JOIN order_category AS oc

        ON vp.order_id = oc.order_id

    GROUP BY oc.category, vp.payment_type

)

SELECT

    category,

    payment_type,

    orders,

    ROUND(

        100.0 * orders / NULLIF(SUM(orders) OVER (PARTITION BY category), 0),

        2

    ) AS order_share_in_category_pct

FROM category_payment

ORDER BY category, orders DESC;

GO



-- 08. STATE X PAYMENT MIX

WITH valid_pay AS (

    SELECT

        p.order_id,

        p.payment_type,

        p.payment_value,

        o.customer_id

    FROM dbo.order_payments AS p

    INNER JOIN dbo.orders AS o

        ON p.order_id = o.order_id

    WHERE o.order_status <> 'canceled'

      AND o.order_approved_at IS NOT NULL

),

state_payment AS (

    SELECT

        c.customer_state AS state,

        vp.payment_type,

        COUNT(DISTINCT vp.order_id) AS orders,

        SUM(vp.payment_value) AS revenue

    FROM valid_pay AS vp

    INNER JOIN dbo.customers_clean AS c

        ON vp.customer_id = c.customer_id

    GROUP BY c.customer_state, vp.payment_type

)

SELECT

    state,

    payment_type,

    orders,

    CAST(revenue AS decimal(15,2)) AS revenue,

    ROUND(

        100.0 * orders / NULLIF(SUM(orders) OVER (PARTITION BY state), 0),

        2

    ) AS order_share_in_state_pct,

    ROUND(

        100.0 * revenue / NULLIF(SUM(revenue) OVER (PARTITION BY state), 0),

        2

    ) AS revenue_share_in_state_pct

FROM state_payment

ORDER BY state, orders DESC;

GO



-- 09. CATEGORY LOGISTICS BURDEN

WITH category_logistics AS (

    SELECT

        COALESCE(t.product_category_name_english, 'unknown_category') AS category,

        SUM(oi.price) AS gross_item_revenue,

        SUM(oi.freight_value) AS freight_cost

    FROM dbo.order_itemst AS oi

    INNER JOIN dbo.products AS pr

        ON oi.product_id = pr.product_id

    LEFT JOIN dbo.product_category_name_translation AS t

        ON LOWER(pr.product_category_name) = LOWER(t.product_category_name)

    INNER JOIN dbo.orders AS o

        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY COALESCE(t.product_category_name_english, 'unknown_category')

)

SELECT

    category AS product_category,

    CAST(gross_item_revenue AS decimal(15,2)) AS gross_item_revenue,

    CAST(freight_cost AS decimal(15,2)) AS freight_cost,

    CAST(100.0 * freight_cost / NULLIF(gross_item_revenue, 0) AS decimal(10,2)) AS logistics_burden_pct

FROM category_logistics

WHERE gross_item_revenue > 1000

ORDER BY logistics_burden_pct DESC;

GO



-- 10. STATE LOGISTICS BURDEN

WITH state_logistics AS (

    SELECT

        c.customer_state,

        SUM(oi.price) AS gross_item_revenue,

        SUM(oi.freight_value) AS freight_cost

    FROM dbo.orders AS o

    INNER JOIN dbo.order_itemst AS oi

        ON o.order_id = oi.order_id

    INNER JOIN dbo.customers_clean AS c

        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_state

)

SELECT

    customer_state AS state,

    CAST(gross_item_revenue AS decimal(15,2)) AS gross_item_revenue,

    CAST(freight_cost AS decimal(15,2)) AS freight_cost,

    CAST(100.0 * freight_cost / NULLIF(gross_item_revenue, 0) AS decimal(10,2)) AS logistics_burden_pct

FROM state_logistics

ORDER BY logistics_burden_pct DESC;

GO



-- 11. YEARLY CATEGORY ITEM REVENUE TREND

SELECT

    YEAR(o.order_approved_at) AS [year],

    COALESCE(t.product_category_name_english, 'unknown_category') AS category,

    COUNT(*) AS item_rows,

    COUNT(DISTINCT oi.order_id) AS orders,

    CAST(SUM(oi.price) AS decimal(15,2)) AS gross_item_revenue

FROM dbo.order_itemst AS oi

INNER JOIN dbo.products AS pr

    ON oi.product_id = pr.product_id

LEFT JOIN dbo.product_category_name_translation AS t

    ON LOWER(pr.product_category_name) = LOWER(t.product_category_name)

INNER JOIN dbo.orders AS o

    ON oi.order_id = o.order_id

WHERE o.order_status <> 'canceled'

  AND o.order_approved_at IS NOT NULL

GROUP BY

    YEAR(o.order_approved_at),

    COALESCE(t.product_category_name_english, 'unknown_category')

ORDER BY [year], gross_item_revenue DESC;

GO



-- 12. TOP CUSTOMER DENSITY LOCATIONS

SELECT

    c.customer_city,

    c.customer_state,

    COUNT(DISTINCT c.customer_unique_id) AS unique_customers

FROM dbo.customers_clean AS c

GROUP BY c.customer_city, c.customer_state

ORDER BY unique_customers DESC;

GO 

-- 13. PAYMENT METHOD RISK AND VOLUME ANALYSIS (INC. BOLETO)
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
    AS decimal(10,2)) AS order_share_pct,
    
    -- İptal Oranı (%)
    CAST(100.0 * COUNT(DISTINCT CASE WHEN o.order_status = 'canceled' THEN o.order_id END) 
         / NULLIF(COUNT(DISTINCT op.order_id), 0) 
    AS decimal(10,2)) AS cancel_rate_pct,
    
    -- Ortalama Onay Süresi (Saat) - Tekilleştirilmiş veri üzerinden kusursuz ortalama
    CAST(AVG(1.0 * DATEDIFF(hour, o.order_purchase_timestamp, o.order_approved_at)) 
    AS decimal(10,1)) AS avg_approval_lag_hours
FROM OrderPaymentsDeduped AS op
INNER JOIN dbo.orders AS o 
    ON op.order_id = o.order_id
GROUP BY op.payment_type
ORDER BY total_orders DESC;
GO
