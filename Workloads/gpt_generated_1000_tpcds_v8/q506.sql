WITH sales_cube AS (
  SELECT
    d.d_year,
    hd.hd_buy_potential,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 1000000 THEN 'High' ELSE 'Low' END AS sales_level
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  GROUP BY CUBE(d.d_year, hd.hd_buy_potential)
),

ship_modes AS (
  SELECT
    sm.sm_ship_mode_sk,
    sm.sm_type,
    sm.sm_code,
    sm.sm_carrier,
    mode_val
  FROM ship_mode sm
  CROSS JOIN UNNEST(ARRAY[sm.sm_code, sm.sm_carrier]) AS t(mode_val)
),

intersect_modes AS (
  SELECT sm1.sm_ship_mode_sk
  FROM ship_mode sm1
  WHERE sm1.sm_type = 'OVERNIGHT'
  INTERSECT
  SELECT sm2.sm_ship_mode_sk
  FROM ship_mode sm2
  WHERE sm2.sm_carrier = 'UPS'
),

final_modes AS (
  SELECT im.sm_ship_mode_sk
  FROM intersect_modes im
  EXCEPT
  SELECT sm3.sm_ship_mode_sk
  FROM ship_mode sm3
  WHERE sm3.sm_code = 'BIKE'
)

SELECT
  CONCAT('Year ', CAST(sc.d_year AS VARCHAR), ' - ', COALESCE(sc.hd_buy_potential, 'All')) AS category,
  sc.total_sales AS metric,
  sc.sales_level
FROM sales_cube sc
WHERE sc.d_year IS NOT NULL

UNION ALL

SELECT
  CONCAT('ShipMode ', CAST(fm.sm_ship_mode_sk AS VARCHAR)) AS category,
  NULL AS metric,
  NULL AS sales_level
FROM final_modes fm

ORDER BY metric DESC NULLS LAST, category
LIMIT 100
