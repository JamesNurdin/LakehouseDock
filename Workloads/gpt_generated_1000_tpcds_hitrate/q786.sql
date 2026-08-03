WITH ss AS (
  SELECT *
  FROM store_sales
  TABLESAMPLE BERNOULLI (10)
)
SELECT
  d.d_year,
  i.i_category,
  SUM(ss.ss_ext_sales_price) AS total_store_sales,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
  CASE
    WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFITABLE'
    ELSE 'LOSS'
  END AS profit_status,
  SUM(CASE WHEN sm_cr.sm_code = 'AIR' THEN cr.cr_return_amt_inc_tax ELSE 0 END) AS air_return_amount
FROM ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr ON cr.cr_item_sk = ss.ss_item_sk
                       AND cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_sales ws ON ws.ws_order_number = ss.ss_ticket_number
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
GROUP BY GROUPING SETS (
  (d.d_year, i.i_category),
  (i.i_category),
  ()
)
HAVING SUM(ss.ss_ext_sales_price) > 0
LIMIT 100
