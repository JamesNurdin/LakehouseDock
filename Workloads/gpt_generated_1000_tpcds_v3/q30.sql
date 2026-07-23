WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ext_ship_cost,
        cs.cs_wholesale_cost,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_ship_cdemo_sk IN (349259, 212342)
      AND cs.cs_ext_ship_cost > 100
      AND cs.cs_wholesale_cost BETWEEN 10 AND 50
      AND cs.cs_quantity > 0
      AND cs.cs_net_paid > 0
      AND cs.cs_ext_discount_amt >= 0
)
SELECT
    p.p_promo_name,
    t.t_meal_time,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_quantity) AS avg_quantity,
    COUNT(*) AS sales_count,
    MIN(fs.cs_net_profit) AS min_profit,
    MAX(fs.cs_net_profit) AS max_profit
FROM filtered_sales fs
INNER JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
INNER JOIN time_dim t ON fs.cs_sold_time_sk = t.t_time_sk
WHERE p.p_start_date_sk >= 2450153
  AND p.p_channel_radio = 'N'
  AND t.t_second <= 10
  AND t.t_meal_time = 'lunch'
GROUP BY p.p_promo_name, t.t_meal_time
HAVING SUM(fs.cs_net_paid) > 10000
   AND COUNT(*) >= 100
ORDER BY total_net_paid DESC
