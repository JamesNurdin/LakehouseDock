WITH promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_coupon_amt) AS avg_coupon,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450840 AND 2450906
      AND cs.cs_order_number IN (263957, 263958, 263959, 263960, 263961)
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name
    HAVING SUM(cs.cs_ext_sales_price) > 10000
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.distinct_orders,
    p.total_quantity,
    p.total_sales,
    p.total_discount,
    p.avg_coupon,
    p.total_profit,
    RANK() OVER (ORDER BY p.total_profit DESC) AS profit_rank
FROM promo_agg p
ORDER BY p.total_profit DESC
LIMIT 50
