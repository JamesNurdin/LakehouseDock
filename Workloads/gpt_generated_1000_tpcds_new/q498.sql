WITH
  sales_returns AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      td.t_hour,
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cp.cp_department,
      cp.cp_catalog_number,
      sm.sm_type,
      w.w_warehouse_name,
      w.w_state,
      c.c_customer_id,
      cd.cd_gender,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      r.r_reason_desc
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_department = 'Books'
      AND cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
  ),
  inventory_agg AS (
    SELECT
      inv.inv_warehouse_sk,
      SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
  ),
  full_sales_returns AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
  ),
  filtered AS (
    SELECT *
    FROM sales_returns sr
    WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns srt
      WHERE srt.sr_item_sk = sr.cs_item_sk
    )
  ),
  final AS (
    SELECT
      f.cs_order_number,
      f.cs_item_sk,
      f.cs_quantity,
      f.cs_net_paid,
      f.cr_return_quantity,
      f.cr_return_amount,
      i.total_qty_on_hand,
      sm.sm_ship_mode_sk,
      -- correlated scalar subquery: total web‑sales net paid for the same ship mode
      (SELECT SUM(ws.ws_net_paid)
       FROM web_sales ws
       WHERE ws.ws_ship_mode_sk = sm.sm_ship_mode_sk) AS ship_mode_web_sales_total,
      -- correlated scalar subquery: distinct buying customers for the same item
      (SELECT COUNT(DISTINCT cs2.cs_bill_customer_sk)
       FROM catalog_sales cs2
       WHERE cs2.cs_item_sk = f.cs_item_sk) AS distinct_buyers
    FROM full_sales_returns f
    LEFT JOIN inventory_agg i ON f.cs_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN ship_mode sm ON f.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE f.cs_net_paid > 1000
      AND (f.cr_return_amount IS NULL OR f.cr_return_amount < 500)
  )
SELECT
  f.cs_order_number,
  f.cs_item_sk,
  f.cs_quantity,
  f.cs_net_paid,
  f.cr_return_quantity,
  f.cr_return_amount,
  f.total_qty_on_hand,
  f.ship_mode_web_sales_total,
  f.distinct_buyers
FROM final f
WHERE f.cs_order_number IN (
  SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 5
  INTERSECT
  SELECT cr_order_number FROM catalog_returns WHERE cr_return_quantity > 0
)
ORDER BY f.cs_net_paid DESC
LIMIT 100
