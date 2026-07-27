WITH
  cr_agg AS (
    SELECT
      cr_catalog_page_sk,
      cr_ship_mode_sk,
      cr_returning_hdemo_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450800 AND 2451000
      AND cr_return_quantity > 1
    GROUP BY cr_catalog_page_sk, cr_ship_mode_sk, cr_returning_hdemo_sk
  ),
  order_filter AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_ship_date_sk = 2452702
      AND ws_ship_mode_sk IN (
        SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR'
      )
    UNION
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_ship_date_sk = 2452638
      AND ws_ship_mode_sk IN (
        SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'GROUND'
      )
  )
SELECT
  cp.cp_department,
  sm.sm_type,
  hd.hd_buy_potential,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(cr_agg.total_return_amount) AS total_returns,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
  (
    SELECT MAX(hd2.hd_income_band_sk)
    FROM household_demographics hd2
  ) AS max_income_band
FROM order_filter of
JOIN web_sales ws ON ws.ws_order_number = of.ws_order_number
JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
JOIN household_demographics hd ON hd.hd_demo_sk = ws.ws_ship_hdemo_sk
JOIN cr_agg ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr_agg.cr_catalog_page_sk
WHERE cp.cp_start_date_sk >= 2450800
  AND cp.cp_end_date_sk <= 2451100
  AND sm.sm_carrier = 'UPS'
  AND hd.hd_vehicle_count >= 1
GROUP BY cp.cp_department, sm.sm_type, hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
