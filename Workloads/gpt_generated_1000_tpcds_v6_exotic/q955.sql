WITH filtered_sales AS (
    SELECT
        cs.cs_ship_customer_sk,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid_inc_tax,
        cs.cs_sold_date_sk,
        p.p_promo_id,
        p.p_channel_dmail
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_ship_cost > 300
      AND p.p_channel_dmail = 'Y'
),
combined_sales AS (
    SELECT
        fs.cs_ship_customer_sk AS customer_id,
        SUM(fs.cs_ext_ship_cost) AS total_ship_cost
    FROM filtered_sales fs
    WHERE fs.cs_sold_date_sk BETWEEN 2450100 AND 2450200
    GROUP BY fs.cs_ship_customer_sk

    UNION ALL

    SELECT
        cs.cs_ship_customer_sk AS customer_id,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost
    FROM catalog_sales cs
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_net_paid_inc_tax > 2000
      AND (p.p_promo_id IS NULL OR p.p_promo_id <> 'AAAAAAAAPAAAAAAA')
    GROUP BY cs.cs_ship_customer_sk
)
SELECT DISTINCT
    cs.customer_id,
    cs.total_ship_cost
FROM combined_sales cs
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    JOIN promotion p2
        ON cs2.cs_promo_sk = p2.p_promo_sk
    WHERE cs2.cs_ship_customer_sk = cs.customer_id
      AND p2.p_promo_id = 'AAAAAAAAPAAAAAAA'
)
ORDER BY cs.total_ship_cost DESC
LIMIT 100
