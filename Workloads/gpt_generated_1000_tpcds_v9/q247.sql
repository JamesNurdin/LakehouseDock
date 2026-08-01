SELECT
  d_date.d_year,
  d_date.d_month_seq,
  cc.cc_division,
  cc.cc_name,
  r_sr.r_reason_desc AS store_return_reason,
  r_wr.r_reason_desc AS web_return_reason,
  wsite.web_state,
  SUM(cs.cs_net_paid) AS total_sales_net_paid,
  SUM(cs.cs_net_profit) AS total_sales_net_profit,
  SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
  SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns,
  COUNT(DISTINCT wr.wr_order_number) AS num_web_returns
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_date
  ON cs.cs_sold_date_sk = d_date.d_date_sk
JOIN time_dim t_time
  ON cs.cs_sold_time_sk = t_time.t_time_sk
LEFT JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_date.d_date_sk
LEFT JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_date.d_date_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE cc.cc_division = 2
  AND cc.cc_tax_percentage > 0.05
  AND d_date.d_year = 2001
  AND d_date.d_month_seq = 5
  AND t_time.t_hour BETWEEN 9 AND 18
  AND cs.cs_quantity > 5
  AND cs.cs_net_profit > 0
  AND r_sr.r_reason_desc LIKE '%model%'
  AND ws.ws_net_profit > 50
  AND wsite.web_state = 'CA'
  AND cs.cs_order_number NOT IN (
    SELECT ws2.ws_order_number
    FROM web_sales ws2
    WHERE ws2.ws_quantity < 1
  )
GROUP BY d_date.d_year,
         d_date.d_month_seq,
         cc.cc_division,
         cc.cc_name,
         r_sr.r_reason_desc,
         r_wr.r_reason_desc,
         wsite.web_state
ORDER BY total_sales_net_profit DESC,
         d_date.d_year,
         d_date.d_month_seq
LIMIT 100
