WITH web_data AS (
  SELECT
    sm.sm_carrier,
    hd.hd_income_band_sk,
    ws.ws_ext_sales_price,
    ws.ws_coupon_amt,
    ws.ws_ext_discount_amt,
    ARRAY[ws.ws_ext_discount_amt, ws.ws_coupon_amt] AS discounts_array,
    ws.ws_order_number
  FROM web_sales ws
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE hd.hd_vehicle_count > 0
    AND ws.ws_ext_sales_price > 1000
    AND w.w_state = 'CA'
),
web_unnested AS (
  SELECT
    sm_carrier AS carrier,
    hd_income_band_sk AS income_band,
    ws_order_number AS order_number,
    discount_val
  FROM web_data
  CROSS JOIN UNNEST(discounts_array) AS t(discount_val)
),
store_data AS (
  SELECT
    hd.hd_income_band_sk,
    ss.ss_ext_sales_price,
    ss.ss_coupon_amt,
    ss.ss_ext_discount_amt,
    ARRAY[ss.ss_ext_discount_amt, ss.ss_coupon_amt] AS discounts_array,
    ss.ss_ticket_number
  FROM store_sales ss
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_vehicle_count >= 0
    AND ss.ss_ext_sales_price > 1000
    AND EXISTS (
      SELECT 1 FROM warehouse w2 WHERE w2.w_gmt_offset > -5
    )
)
SELECT
  carrier,
  income_band,
  SUM(discount_val) AS total_discount,
  (SELECT MAX(hd_income_band_sk) FROM household_demographics) AS max_income_band
FROM web_unnested
GROUP BY carrier, income_band

UNION ALL

SELECT
  'store' AS carrier,
  income_band,
  SUM(discount_val) AS total_discount,
  (SELECT MAX(hd_income_band_sk) FROM household_demographics) AS max_income_band
FROM (
  SELECT
    hd_income_band_sk AS income_band,
    discounts_array
  FROM store_data
) s
CROSS JOIN UNNEST(discounts_array) AS t(discount_val)
GROUP BY income_band
LIMIT 100
