WITH store_agg AS (
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_promo_id AS promo_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        'store' AS sales_source
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE p.p_channel_email = 'N'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY p.p_promo_sk, p.p_promo_id
),
catalog_agg AS (
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_promo_id AS promo_id,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        'catalog' AS sales_source
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE p.p_discount_active = 'Y'
      AND t.t_shift = 'Evening'
    GROUP BY p.p_promo_sk, p.p_promo_id
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
)
SELECT
    c.promo_id,
    c.promo_sk,
    c.total_sales,
    c.sales_source
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN customer cu ON ss.ss_customer_sk = cu.c_customer_sk
    WHERE ss.ss_promo_sk = c.promo_sk
      AND cu.c_preferred_cust_flag = 'Y'
)
ORDER BY c.total_sales DESC
LIMIT 100
