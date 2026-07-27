SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_category,
    sm.sm_type,
    ws.ws_ship_mode_sk,
    ws_site.web_state,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_returns,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_net_profit) AS avg_profit,
    MIN(ws.ws_ext_sales_price) AS min_sale,
    MAX(ws.ws_ext_sales_price) AS max_sale
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
  AND ws.ws_item_sk = wr.wr_item_sk
  AND wr.wr_return_amt_inc_tax > 1000
LEFT JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2001
  AND t_sold.t_hour BETWEEN 9 AND 17
  AND i.i_brand = 'Brand#23'
  AND sm.sm_type = 'AIR'
  AND ws_site.web_state = 'CA'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_category,
    sm.sm_type,
    ws.ws_ship_mode_sk,
    ws_site.web_state
ORDER BY total_sales DESC
LIMIT 100
