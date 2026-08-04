WITH filtered_sales AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_wholesale_cost,
        cs.cs_coupon_amt,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_list_price
    FROM catalog_sales cs
    WHERE cs.cs_wholesale_cost > 10.00
      AND cs.cs_coupon_amt < 1000.00
      AND cs.cs_net_paid_inc_ship_tax BETWEEN 500.00 AND 4000.00
),
filtered_promos AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_channel_catalog
    FROM promotion p
    WHERE p.p_start_date_sk >= 2450324
      AND p.p_channel_catalog = 'N'
)
SELECT
    p.p_promo_name,
    COUNT(cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_paid_inc_ship_tax,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
    MIN(cs.cs_wholesale_cost) AS min_wholesale_cost,
    MAX(cs.cs_list_price) AS max_list_price
FROM filtered_sales cs
FULL OUTER JOIN filtered_promos p
    ON cs.cs_promo_sk = p.p_promo_sk
GROUP BY p.p_promo_name
ORDER BY total_paid_inc_ship_tax DESC
LIMIT 100
