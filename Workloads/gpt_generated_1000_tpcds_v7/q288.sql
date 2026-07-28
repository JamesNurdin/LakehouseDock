WITH catalog_agg AS (
  SELECT
    p.p_promo_name AS promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_quantity,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE t.t_hour BETWEEN 9 AND 17
    AND hd.hd_vehicle_count >= 1
  GROUP BY p.p_promo_name
),
store_agg AS (
  SELECT
    p.p_promo_name AS promo_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_quantity) AS total_quantity,
    'store' AS sales_channel
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE t.t_hour BETWEEN 9 AND 17
    AND hd.hd_vehicle_count >= 1
  GROUP BY p.p_promo_name
)
SELECT promo_name, total_net_paid, total_quantity, sales_channel
FROM catalog_agg
UNION ALL
SELECT promo_name, total_net_paid, total_quantity, sales_channel
FROM store_agg
ORDER BY total_net_paid DESC
