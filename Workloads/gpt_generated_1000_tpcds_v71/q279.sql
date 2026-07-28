WITH ss_data AS (
  SELECT
    d_ss.d_year AS year,
    i.i_category AS category,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_type,
    CAST(NULL AS varchar) AS website_name,
    ss.ss_ext_sales_price AS sales_amount,
    ss.ss_quantity AS quantity,
    ss.ss_net_profit AS profit
  FROM store_sales ss
  JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = d_ss.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d_ss.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
),
ws_data AS (
  SELECT
    d_ws.d_year AS year,
    i.i_category AS category,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_type,
    ws_site.web_name AS website_name,
    ws.ws_ext_sales_price AS sales_amount,
    ws.ws_quantity AS quantity,
    ws.ws_net_profit AS profit
  FROM web_sales ws
  JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = d_ws.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE d_ws.d_year = 2001
    AND ws_site.web_manager = 'Jason Silva'
    AND sm.sm_carrier = 'CarrierX'
    AND ws.ws_quantity > 2
    AND EXISTS (SELECT 1 FROM store_sales ss2 WHERE ss2.ss_item_sk = ws.ws_item_sk AND ss2.ss_sold_date_sk = ws.ws_sold_date_sk)
),
combined AS (
  SELECT * FROM ss_data
  UNION ALL
  SELECT * FROM ws_data
)
SELECT
  combined.year,
  combined.category,
  combined.call_center_name,
  combined.ship_type,
  combined.website_name,
  COUNT(*) AS transaction_count,
  SUM(combined.sales_amount) AS total_sales,
  AVG(combined.sales_amount) AS avg_sales,
  SUM(combined.profit) AS total_profit,
  MAX(combined.quantity) AS max_quantity,
  (SELECT MIN(i_current_price) FROM item WHERE i_category = combined.category) AS min_item_price
FROM combined
GROUP BY
  combined.year,
  combined.category,
  combined.call_center_name,
  combined.ship_type,
  combined.website_name
HAVING
  SUM(combined.sales_amount) > 5000
  AND COUNT(*) >= 5
  AND MAX(combined.quantity) > 10
ORDER BY total_sales DESC
LIMIT 100
