WITH catalog AS (
  SELECT
    cc.cc_state AS cc_state,
    w.w_state AS w_state,
    t.t_hour AS hour,
    SUM(cs.cs_net_profit) AS catalog_net_profit
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE cc.cc_manager = 'Bob Belcher'
    AND cc.cc_rec_start_date >= DATE '2000-01-01'
    AND t.t_hour BETWEEN 9 AND 18
  GROUP BY cc.cc_state, w.w_state, t.t_hour
),
web AS (
  SELECT
    w.w_state AS w_state,
    t.t_hour AS hour,
    SUM(ws.ws_net_profit) AS web_net_profit
  FROM web_sales ws
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 9 AND 18
  GROUP BY w.w_state, t.t_hour
),
returns AS (
  SELECT
    t.t_hour AS hour,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE r.r_reason_desc = 'Damaged item'
    AND t.t_hour BETWEEN 9 AND 18
  GROUP BY t.t_hour
)
SELECT
  ca.cc_state,
  ca.w_state,
  ca.hour,
  ca.catalog_net_profit,
  COALESCE(wb.web_net_profit, 0) AS web_net_profit,
  COALESCE(r.total_return_qty, 0) AS return_qty,
  COALESCE(r.total_return_loss, 0) AS return_loss,
  (ca.catalog_net_profit + COALESCE(wb.web_net_profit, 0) - COALESCE(r.total_return_loss, 0)) AS total_net_profit
FROM catalog ca
LEFT JOIN web wb
  ON ca.w_state = wb.w_state
  AND ca.hour = wb.hour
LEFT JOIN returns r
  ON ca.hour = r.hour
WHERE (ca.catalog_net_profit + COALESCE(wb.web_net_profit, 0) - COALESCE(r.total_return_loss, 0)) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
