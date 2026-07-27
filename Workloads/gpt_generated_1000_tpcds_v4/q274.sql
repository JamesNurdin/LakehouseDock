WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_press,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        MIN(cs.cs_ext_ship_cost) AS min_ship_cost,
        MAX(cs.cs_wholesale_cost) AS max_wholesale_cost
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_wholesale_cost BETWEEN 20 AND 100
      AND cs.cs_ext_ship_cost < 2000
      AND p.p_cost > 500
      AND p.p_end_date_sk BETWEEN 2450300 AND 2450500
      AND p.p_channel_press = 'N'
      AND cs.cs_ship_customer_sk IN (3089367, 8238393)
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_channel_press
)
SELECT
    p_promo_id,
    p_promo_name,
    p_channel_press,
    total_sales,
    avg_profit,
    orders_cnt,
    min_ship_cost,
    max_wholesale_cost,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
