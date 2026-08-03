SELECT
  cc.cc_name,
  r.r_reason_desc,
  td.t_hour,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(ws.ws_net_paid) AS total_web_sales,
  SUM(wr.wr_return_amt) AS total_return_amount,
  AVG(ws.ws_quantity) AS avg_web_quantity,
  CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_order_number = ws.ws_order_number
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE cc.cc_mkt_id IN (1, 3, 5)
  AND cc.cc_city = 'Seattle'
  AND cs.cs_ship_customer_sk = 10262838
  AND cs.cs_quantity > 5
  AND ws.ws_net_profit > 0
  AND wr.wr_return_tax > 100.00
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY cc.cc_name, r.r_reason_desc, td.t_hour
ORDER BY total_web_sales DESC
LIMIT 100
