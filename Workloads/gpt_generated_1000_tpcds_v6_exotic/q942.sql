WITH joined_data AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    d_sold.d_year,
    w.w_state,
    sm.sm_type,
    cust_bill.c_customer_id,
    wr.wr_return_amt,
    site.web_country,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    (
      SELECT avg(wr2.wr_return_amt)
      FROM web_returns wr2
      JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
      WHERE d2.d_year = d_sold.d_year
        AND wr2.wr_returning_customer_sk = cust_bill.c_customer_sk
    ) AS avg_return_amt_cust_year
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN customer cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer cust_ship ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
  JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk AND cp.cp_end_date_sk = d_ship.d_date_sk
  WHERE d_sold.d_year = 2001
    AND w.w_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND hd_bill.hd_dep_count >= 2
    AND site.web_country = 'United States'
    AND wr.wr_return_amt > 100
    AND NOT EXISTS (
      SELECT 1
      FROM web_returns wr2
      JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
      WHERE wr2.wr_order_number = ws.ws_order_number
        AND d2.d_year = d_sold.d_year
        AND wr2.wr_return_amt > 1000
    )
),
aggregated AS (
  SELECT
    d_year,
    w_state,
    sm_type,
    profit_category,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(wr_return_amt) AS total_returns,
    AVG(avg_return_amt_cust_year) AS avg_return_amt_cust_year,
    SUM(ws_net_profit) AS total_profit
  FROM joined_data
  GROUP BY ROLLUP (d_year, w_state, sm_type, profit_category)
)
SELECT
  d_year,
  w_state,
  sm_type,
  profit_category,
  order_cnt,
  total_sales,
  total_returns,
  avg_return_amt_cust_year,
  total_profit,
  RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year
FROM aggregated
ORDER BY profit_rank_year ASC, d_year ASC
LIMIT 100
