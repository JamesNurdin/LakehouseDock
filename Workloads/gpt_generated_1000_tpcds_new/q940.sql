WITH
  sales_full AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_ticket_number,
      ss.ss_net_profit,
      d_sales.d_date,
      t_sales.t_hour AS sold_hour,
      s.s_store_name,
      s.s_state,
      s.s_tax_percentage
    FROM store_sales ss
    FULL OUTER JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
      ON ss.ss_sold_time_sk = t_sales.t_time_sk
  ),
  returns_full AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_return_amount,
      cr.cr_store_credit,
      cr.cr_fee,
      d_ret.d_date,
      t_ret.t_hour,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
      ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
  ),
  inventory_by_date AS (
    SELECT
      i.inv_date_sk,
      SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    GROUP BY i.inv_date_sk
  ),
  order_exclusive AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    EXCEPT
    SELECT wr.wr_order_number
    FROM web_returns wr
  )
SELECT
  s.d_date,
  s.s_store_name,
  s.s_state,
  s.ss_ticket_number,
  s.ss_net_profit,
  CASE
    WHEN s.ss_net_profit > 10000 THEN 'High'
    WHEN s.ss_net_profit > 0    THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  COALESCE(r.cr_return_amount, 0) AS return_amount,
  COALESCE(r.cr_store_credit, 0) AS store_credit,
  COALESCE(r.cr_fee, 0)         AS return_fee,
  inv.total_qty,
  ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY s.ss_net_profit DESC) AS profit_rank_state,
  RANK()       OVER (ORDER BY s.ss_net_profit DESC)                AS overall_profit_rank,
  CASE WHEN EXISTS (SELECT 1 FROM order_exclusive oe WHERE oe.order_number = s.ss_ticket_number) THEN 1 ELSE 0 END AS exclusive_catalog_order_flag
FROM sales_full s
LEFT JOIN returns_full r
  ON s.ss_sold_date_sk = r.cr_returned_date_sk
 AND s.ss_sold_time_sk = r.cr_returned_time_sk
LEFT JOIN LATERAL (
  SELECT total_qty
  FROM inventory_by_date ibd
  WHERE ibd.inv_date_sk = s.ss_sold_date_sk
) inv ON TRUE
WHERE s.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND s.s_state = 'CA'
  AND s.sold_hour BETWEEN 9 AND 17
LIMIT 100
