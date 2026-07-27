WITH base_data AS (
  SELECT
    cp.cp_department AS cp_department,
    d.d_year AS d_year,
    hd.hd_buy_potential AS hd_buy_potential,
    hd.hd_vehicle_count,
    c.c_customer_id,
    p.p_cost,
    wp.wp_char_count,
    cp.cp_type,
    p.p_discount_active
  FROM catalog_page cp
  JOIN date_dim d
    ON cp.cp_start_date_sk = d.d_date_sk
  JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
  JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
  JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_year = 2001
    AND cp.cp_type = 'monthly'
    AND hd.hd_vehicle_count >= 2
    AND p.p_discount_active = 'Y'
),
agg_data AS (
  SELECT
    cp_department,
    d_year,
    hd_buy_potential,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(p_cost) AS total_promo_cost,
    AVG(wp_char_count) AS avg_char_count
  FROM base_data
  GROUP BY cp_department, d_year, hd_buy_potential
  HAVING COUNT(DISTINCT c_customer_id) > 5
)
SELECT
  cp_department,
  d_year,
  hd_buy_potential,
  unique_customers,
  total_promo_cost,
  avg_char_count,
  ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_promo_cost DESC) AS dept_rank
FROM agg_data
ORDER BY total_promo_cost DESC, cp_department
