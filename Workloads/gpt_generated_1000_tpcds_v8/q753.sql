WITH
  order_diff AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
  ),
  item_intersect AS (
    SELECT i.i_item_sk
    FROM item i
    INTERSECT
    SELECT inv.inv_item_sk
    FROM (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv
  ),
  joined AS (
    SELECT
      d_ws.d_year,
      s.s_store_name,
      w.w_state,
      i.i_product_name,
      p.p_promo_id,
      ws.ws_net_profit,
      ws.ws_order_number,
      i.i_item_sk,
      CASE WHEN ws.ws_order_number IN (SELECT ws_order_number FROM order_diff) THEN 1 ELSE 0 END AS order_in_diff,
      CASE WHEN EXISTS (SELECT 1 FROM item_intersect ii WHERE ii.i_item_sk = i.i_item_sk) THEN 1 ELSE 0 END AS item_in_sample,
      (SELECT SUM(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_item_sk = i.i_item_sk) AS total_return_amount
    FROM web_sales ws
      JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
      JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
      JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
      JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
      JOIN store s ON sr.sr_store_sk = s.s_store_sk
      JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
      JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
      JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
      JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
      JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
      JOIN (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv ON inv.inv_item_sk = i.i_item_sk
      JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
      JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    WHERE d_ws.d_year = 2001
      AND i.i_current_price > 20
      AND w.w_state = 'CA'
  )
SELECT
  d_year,
  s_store_name,
  w_state,
  i_product_name,
  p_promo_id,
  SUM(ws_net_profit) AS total_profit,
  COUNT(DISTINCT ws_order_number) AS distinct_orders,
  MAX(total_return_amount) AS total_return_amount,
  MAX(order_in_diff) AS order_in_diff_flag,
  MAX(item_in_sample) AS item_in_sample_flag,
  RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM joined
GROUP BY CUBE (d_year, s_store_name, w_state, i_product_name, p_promo_id)
HAVING SUM(ws_net_profit) > 0
ORDER BY d_year, profit_rank
LIMIT 100
