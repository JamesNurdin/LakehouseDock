WITH base AS (
  SELECT
    cp.cp_department AS department,
    p.p_promo_name AS promo_name,
    w.w_city AS city,
    s.s_state AS state,
    d.d_year AS year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(*) AS txn_count
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
   AND p.p_start_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND p.p_cost > 500
    AND w.w_state = 'CA'
    AND s.s_state = 'TX'
    AND cp.cp_department = 'Electronics'
    AND cr.cr_return_quantity > 0
  GROUP BY cp.cp_department, p.p_promo_name, w.w_city, s.s_state, d.d_year
)
SELECT
  department,
  promo_name,
  city,
  state,
  year,
  total_return_amount,
  total_net_profit,
  txn_count,
  total_return_amount / NULLIF(txn_count, 0) AS avg_return_amount_per_txn,
  total_net_profit / NULLIF(txn_count, 0) AS avg_net_profit_per_txn
FROM base
WHERE total_return_amount > 1000
ORDER BY avg_net_profit_per_txn DESC
LIMIT 100
