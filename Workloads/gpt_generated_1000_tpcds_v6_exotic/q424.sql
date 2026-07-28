WITH sub_a AS (
  SELECT
    p.p_promo_id,
    sm.sm_ship_mode_id,
    td.t_meal_time,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    (
      SELECT AVG(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_promo_sk = cs.cs_promo_sk
    ) AS avg_sales_price
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE p.p_channel_dmail = 'Y'
    AND sm.sm_contract LIKE 'X%'
    AND td.t_meal_time = 'lunch'
  GROUP BY p.p_promo_id, sm.sm_ship_mode_id, td.t_meal_time, cs.cs_promo_sk
),
sub_b AS (
  SELECT
    p.p_promo_id,
    sm.sm_ship_mode_id,
    td.t_meal_time,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    (
      SELECT AVG(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_promo_sk = cs.cs_promo_sk
    ) AS avg_sales_price
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE p.p_channel_email = 'Y'
    AND sm.sm_contract LIKE '%Z'
    AND td.t_meal_time = 'dinner'
  GROUP BY p.p_promo_id, sm.sm_ship_mode_id, td.t_meal_time, cs.cs_promo_sk
),
combined AS (
  SELECT * FROM sub_a
  UNION ALL
  SELECT * FROM sub_b
)
SELECT
  p_promo_id,
  sm_ship_mode_id,
  t_meal_time,
  total_sales,
  sales_cnt,
  avg_sales_price,
  ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_sales DESC) AS promo_rank
FROM combined
ORDER BY total_sales DESC
LIMIT 100
