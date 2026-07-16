WITH wr_time AS (
   SELECT
     t.t_hour,
     t.t_shift,
     SUM(wr.wr_return_amt) AS total_return_amt,
     SUM(wr.wr_refunded_cash) AS total_refunded_cash,
     COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 8 AND 20
   GROUP BY t.t_hour, t.t_shift
   HAVING SUM(wr.wr_return_amt) > 1000
),
inv_wh AS (
   SELECT
     w.w_warehouse_name,
     w.w_state,
     SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
     COUNT(*) AS sku_cnt
   FROM inventory i
   JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
   WHERE w.w_state IN ('CA', 'TX', 'NY')
   GROUP BY w.w_warehouse_name, w.w_state
   HAVING SUM(i.inv_quantity_on_hand) > 5000
)
SELECT
  wr.t_hour,
  wr.t_shift,
  wr.total_return_amt,
  wr.return_cnt,
  inv.w_warehouse_name,
  inv.total_qty_on_hand,
  RANK() OVER (PARTITION BY wr.t_shift ORDER BY wr.total_return_amt DESC) AS hour_rank_by_return,
  ROW_NUMBER() OVER (ORDER BY inv.total_qty_on_hand DESC) AS warehouse_qty_rank
FROM wr_time wr
CROSS JOIN inv_wh inv
ORDER BY wr.total_return_amt DESC, inv.total_qty_on_hand DESC
LIMIT 50
