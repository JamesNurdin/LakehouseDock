WITH sales_no_promo AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_paid) > 5000 THEN 'HIGH' ELSE 'LOW' END AS spend_category
    FROM catalog_sales cs
    WHERE NOT EXISTS (
        SELECT 1 FROM promotion p WHERE p.p_promo_sk = cs.cs_promo_sk
    )
    GROUP BY cs.cs_bill_customer_sk
),
store_returns_us AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        CASE WHEN SUM(sr.sr_return_amt) > 2000 THEN 'LARGE' ELSE 'SMALL' END AS return_size
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_country = 'United States'
    GROUP BY sr.sr_customer_sk
)
SELECT
    customer_sk,
    total_net_paid,
    spend_category,
    NULL AS total_return_amt,
    NULL AS return_size
FROM sales_no_promo
UNION ALL
SELECT
    customer_sk,
    NULL AS total_net_paid,
    NULL AS spend_category,
    total_return_amt,
    return_size
FROM store_returns_us
ORDER BY customer_sk
LIMIT 100
