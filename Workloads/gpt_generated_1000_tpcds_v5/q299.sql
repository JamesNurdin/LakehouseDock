WITH cr_filtered AS (
  SELECT
    cr_order_number,
    cr_return_amount,
    cr_returned_time_sk,
    cr_ship_mode_sk,
    cr_warehouse_sk
  FROM catalog_returns
  WHERE cr_return_amount > 0
)
SELECT
  sm.sm_type,
  td.t_meal_time,
  site.web_site_id,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(COALESCE(crf.cr_return_amount, 0)) AS total_returns,
  COUNT(DISTINCT ws.ws_order_number) AS sales_orders,
  COUNT(DISTINCT crf.cr_order_number) AS return_orders
FROM web_sales ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN cr_filtered crf
  ON crf.cr_returned_time_sk = td.t_time_sk
  AND crf.cr_ship_mode_sk = sm.sm_ship_mode_sk
  AND crf.cr_warehouse_sk = w.w_warehouse_sk
WHERE
  td.t_meal_time = 'lunch'
  AND sm.sm_type = 'AIR'
  AND site.web_gmt_offset = -5.00
  AND ca.ca_city = 'Spring'
GROUP BY
  sm.sm_type,
  td.t_meal_time,
  site.web_site_id
ORDER BY
  total_sales DESC
LIMIT 100
