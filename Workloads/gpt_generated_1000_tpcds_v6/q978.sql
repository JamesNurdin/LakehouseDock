WITH sales_agg AS (
  SELECT
    d_sales.d_year,
    sm.sm_carrier,
    ca_bill.ca_state,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count
  FROM web_sales ws
  JOIN date_dim d_sales
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN inventory inv
    ON d_sales.d_date_sk = inv.inv_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sales.d_date_sk
  WHERE d_sales.d_year = 2000
    AND sm.sm_carrier IN ('DIAMOND', 'PRIVATECARRIER')
    AND ca_bill.ca_state = 'CA'
    AND wp.wp_char_count BETWEEN 2000 AND 4000
    AND inv.inv_quantity_on_hand > 0
    AND t_sold.t_hour BETWEEN 9 AND 17
  GROUP BY GROUPING SETS (
    (d_sales.d_year, sm.sm_carrier, ca_bill.ca_state),
    (d_sales.d_year, sm.sm_carrier),
    (d_sales.d_year),
    ()
  )
)
SELECT
  d_year,
  sm_carrier,
  ca_state,
  total_sales,
  total_web_returns,
  total_store_returns,
  orders_count,
  RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY d_year, total_sales DESC
LIMIT 100
