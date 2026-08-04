WITH
  high_sales_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship_tax > 3000
      AND cs.cs_sold_date_sk BETWEEN 2450816 AND 2450841
    GROUP BY cs.cs_order_number
    HAVING SUM(cs.cs_ext_sales_price) > 20000
  ),
  returned_orders AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
    GROUP BY cr.cr_order_number
  ),
  intersect_orders AS (
    SELECT cs_order_number FROM high_sales_orders
    INTERSECT
    SELECT cr_order_number FROM returned_orders
  ),
  except_orders AS (
    SELECT cs_order_number FROM high_sales_orders
    EXCEPT
    SELECT cr_order_number FROM returned_orders
  ),
  joined_data AS (
    SELECT
      cp.cp_department,
      cp.cp_catalog_page_id,
      w.w_warehouse_name,
      w.w_state,
      w.w_zip,
      sm.sm_ship_mode_id,
      r.r_reason_desc,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid_inc_ship_tax,
      cr.cr_return_amount,
      inv.inv_quantity_on_hand
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
      AND cs.cs_item_sk = cr.cr_item_sk
    INNER JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    INNER JOIN inventory inv
      ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE cs.cs_quantity >= 2
      AND cs.cs_net_paid_inc_ship_tax > 1000
      AND inv.inv_quantity_on_hand >= 500
      AND w.w_state = 'CA'
      AND r.r_reason_desc = 'Damaged'
      AND w.w_zip IN ('19231', '29231')
  )
SELECT
  jd.cp_department,
  jd.cp_catalog_page_id,
  jd.w_warehouse_name,
  jd.w_state,
  jd.w_zip,
  jd.sm_ship_mode_id,
  jd.r_reason_desc,
  SUM(jd.cs_net_paid_inc_ship_tax) AS total_paid,
  SUM(jd.cr_return_amount) AS total_returned,
  (SUM(jd.cs_net_paid_inc_ship_tax) - SUM(jd.cr_return_amount)) AS net_profit,
  ROW_NUMBER() OVER (PARTITION BY jd.cp_department ORDER BY (SUM(jd.cs_net_paid_inc_ship_tax) - SUM(jd.cr_return_amount)) DESC) AS dept_rank
FROM joined_data jd
WHERE jd.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
GROUP BY
  jd.cp_department,
  jd.cp_catalog_page_id,
  jd.w_warehouse_name,
  jd.w_state,
  jd.w_zip,
  jd.sm_ship_mode_id,
  jd.r_reason_desc
ORDER BY net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
