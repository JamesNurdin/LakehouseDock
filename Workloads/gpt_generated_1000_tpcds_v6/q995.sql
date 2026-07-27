SELECT
  cc.cc_name,
  w.w_warehouse_name,
  wp.wp_type,
  SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
  SUM(ws.ws_ext_sales_price) AS web_sales_total,
  SUM(wr.wr_return_amt) AS total_return_amount,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
  AVG(cs.cs_net_profit) AS avg_catalog_profit,
  AVG(ws.ws_net_profit) AS avg_web_profit,
  MIN(cs.cs_ext_sales_price) AS min_catalog_sale,
  MAX(ws.ws_ext_sales_price) AS max_web_sale
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
  AND cc.cc_rec_end_date <= DATE '2001-12-31'
  AND wp.wp_rec_start_date = DATE '2000-09-03'
  AND wp.wp_char_count > 1500
  AND ws.ws_wholesale_cost > 30.00
  AND wr.wr_return_amt > 0
GROUP BY
  cc.cc_name,
  w.w_warehouse_name,
  wp.wp_type
ORDER BY catalog_sales_total DESC
LIMIT 100
