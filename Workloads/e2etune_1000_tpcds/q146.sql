WITH sales_agg AS (
  SELECT
    d.d_fy_quarter_seq AS quarter,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(ws.ws_quantity) AS total_sales_qty,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_fy_quarter_seq BETWEEN 1 AND 4
    AND d.d_holiday = 'N'
  GROUP BY d.d_fy_quarter_seq, w.w_warehouse_sk, w.w_warehouse_name
),
web_returns_total AS (
  SELECT
    d.d_fy_quarter_seq AS quarter,
    w.w_warehouse_sk,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(wr.wr_return_quantity) AS total_web_return_qty
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_fy_quarter_seq BETWEEN 1 AND 4
    AND d.d_holiday = 'N'
  GROUP BY d.d_fy_quarter_seq, w.w_warehouse_sk
),
web_returns_by_reason AS (
  SELECT
    d.d_fy_quarter_seq AS quarter,
    w.w_warehouse_sk,
    r.r_reason_desc,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(wr.wr_return_quantity) AS web_return_qty
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_fy_quarter_seq BETWEEN 1 AND 4
    AND d.d_holiday = 'N'
  GROUP BY d.d_fy_quarter_seq, w.w_warehouse_sk, r.r_reason_desc
),
store_returns_agg AS (
  SELECT
    d.d_fy_quarter_seq AS quarter,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(sr.sr_return_quantity) AS store_return_qty
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_fy_quarter_seq BETWEEN 1 AND 4
    AND d.d_holiday = 'N'
  GROUP BY d.d_fy_quarter_seq
),
web_return_reason_rank AS (
  SELECT
    quarter,
    w_warehouse_sk,
    r_reason_desc,
    web_return_loss,
    RANK() OVER (PARTITION BY quarter, w_warehouse_sk ORDER BY web_return_loss DESC) AS reason_rank
  FROM web_returns_by_reason
)
SELECT
  s.quarter,
  s.w_warehouse_name,
  s.total_sales_profit,
  COALESCE(wrt.total_web_return_loss, 0) AS web_return_loss,
  COALESCE(sr.store_return_loss, 0) AS store_return_loss,
  (s.total_sales_profit - COALESCE(wrt.total_web_return_loss, 0) - COALESCE(sr.store_return_loss, 0)) AS net_profit_after_returns,
  CASE
    WHEN (s.total_sales_profit - COALESCE(wrt.total_web_return_loss, 0) - COALESCE(sr.store_return_loss, 0)) >= 100000 THEN 'HIGH'
    WHEN (s.total_sales_profit - COALESCE(wrt.total_web_return_loss, 0) - COALESCE(sr.store_return_loss, 0)) >= 50000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  RANK() OVER (PARTITION BY s.quarter ORDER BY (s.total_sales_profit - COALESCE(wrt.total_web_return_loss, 0) - COALESCE(sr.store_return_loss, 0)) DESC) AS profit_rank,
  MAX(CASE WHEN rr.reason_rank = 1 THEN rr.r_reason_desc END) AS top_web_return_reason,
  MAX(CASE WHEN rr.reason_rank = 1 THEN rr.web_return_loss END) AS top_web_return_loss
FROM sales_agg s
LEFT JOIN web_returns_total wrt ON s.quarter = wrt.quarter AND s.w_warehouse_sk = wrt.w_warehouse_sk
LEFT JOIN store_returns_agg sr ON s.quarter = sr.quarter
LEFT JOIN web_return_reason_rank rr ON s.quarter = rr.quarter AND s.w_warehouse_sk = rr.w_warehouse_sk
WHERE s.total_sales_profit > 0
GROUP BY
  s.quarter,
  s.w_warehouse_name,
  s.total_sales_profit,
  wrt.total_web_return_loss,
  sr.store_return_loss
ORDER BY s.quarter, net_profit_after_returns DESC
LIMIT 100
