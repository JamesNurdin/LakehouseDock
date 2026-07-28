WITH joined_data AS (
  SELECT
    d.d_year,
    s.s_state,
    s.s_store_name,
    ss.ss_ext_sales_price,
    ws.ws_ext_sales_price,
    ss.ss_ticket_number,
    ws.ws_order_number,
    ib.ib_upper_bound,
    sm.sm_type,
    r.r_reason_desc,
    cc.cc_tax_percentage
  FROM date_dim d
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
  JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
  JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
  JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
  JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND s.s_state = 'CA'
    AND cc.cc_tax_percentage > 0.08
    AND ib.ib_upper_bound <= 50000
    AND sm.sm_type = 'AIR'
    AND r.r_reason_desc = 'Customer not satisfied'
)
SELECT
  d_year,
  s_state,
  s_store_name,
  SUM(ss_ext_sales_price) AS total_store_sales,
  SUM(ws_ext_sales_price) AS total_web_sales,
  COUNT(DISTINCT ss_ticket_number) AS store_txns,
  COUNT(DISTINCT ws_order_number) AS web_txns,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ss_ext_sales_price) DESC) AS store_sales_rank,
  CASE
    WHEN GROUPING(s_store_name) = 1 THEN 'ALL STORES'
    ELSE s_store_name
  END AS store_name_label
FROM joined_data
GROUP BY GROUPING SETS (
  (d_year, s_state, s_store_name),
  (d_year, s_state),
  (d_year),
  ()
)
ORDER BY d_year, s_state, total_store_sales DESC
LIMIT 100
