WITH base_sales AS (
  SELECT
    d.d_year,
    cc.cc_name,
    cp.cp_catalog_page_number,
    t.t_hour,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ws.ws_net_paid,
    ws.ws_net_profit,
    COALESCE(sr.sr_net_loss, 0) AS return_loss,
    (ss.ss_net_profit + ws.ws_net_profit - COALESCE(sr.sr_net_loss, 0)) AS profit_amount
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
  LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
  LEFT JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND cc.cc_tax_percentage > 0.05
    AND cp.cp_catalog_page_number IN (6, 14, 21)
    AND t.t_hour BETWEEN 9 AND 17
    AND ss.ss_quantity > 0
    AND ws.ws_quantity > 0
)
SELECT
  d_year,
  CASE
    WHEN profit_amount > 10000 THEN 'HIGH'
    WHEN profit_amount BETWEEN 0 AND 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  COUNT(*) AS cnt_transactions,
  SUM(ss_net_paid) AS total_store_paid,
  SUM(ws_net_paid) AS total_web_paid,
  SUM(profit_amount) AS total_net_profit,
  AVG(profit_amount) AS avg_net_profit_per_txn
FROM base_sales
GROUP BY
  d_year,
  CASE
    WHEN profit_amount > 10000 THEN 'HIGH'
    WHEN profit_amount BETWEEN 0 AND 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END
HAVING SUM(profit_amount) > 50000
ORDER BY d_year, profit_category
