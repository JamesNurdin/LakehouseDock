/*
Goal: Analyze net profit from catalog sales together with return amounts and available inventory, broken down by catalog page, ship mode and warehouse. The query samples sales data, aggregates sales and returns, joins inventory, and combines two result sets (all orders and only Electronics department) using UNION DISTINCT. It uses a FULL OUTER JOIN to keep orders without returns and vice‑versa, orders the final rows and returns the first 100.
*/
WITH
  sales_base AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of sales rows
  ),
  sales_agg AS (
    SELECT
      cs.cs_order_number,
      cp.cp_catalog_page_id,
      sm.sm_ship_mode_id,
      w.w_warehouse_id,
      SUM(cs.cs_net_profit)        AS total_net_profit,
      SUM(cs.cs_quantity)          AS total_quantity
    FROM sales_base cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    GROUP BY cs.cs_order_number, cp.cp_catalog_page_id, sm.sm_ship_mode_id, w.w_warehouse_id
  ),
  returns_agg AS (
    SELECT
      cr.cr_order_number,
      cp.cp_catalog_page_id,
      sm.sm_ship_mode_id,
      w.w_warehouse_id,
      SUM(cr.cr_return_amount)   AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN household_demographics hd_refund
      ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_return
      ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN household_demographics hd_return
      ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN time_dim td
      ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY cr.cr_order_number, cp.cp_catalog_page_id, sm.sm_ship_mode_id, w.w_warehouse_id
  ),
  inventory_join AS (
    SELECT
      w.w_warehouse_id,
      inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN warehouse w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_date_sk > 2450900
  )
SELECT
  COALESCE(sa.cs_order_number, ra.cr_order_number)          AS order_number,
  COALESCE(sa.cp_catalog_page_id, ra.cp_catalog_page_id)   AS catalog_page_id,
  COALESCE(sa.sm_ship_mode_id, ra.sm_ship_mode_id)         AS ship_mode_id,
  COALESCE(sa.w_warehouse_id, ra.w_warehouse_id)           AS warehouse_id,
  sa.total_net_profit,
  ra.total_return_amount,
  i.inv_quantity_on_hand
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
  ON sa.cs_order_number = ra.cr_order_number
LEFT JOIN inventory_join i
  ON COALESCE(sa.w_warehouse_id, ra.w_warehouse_id) = i.w_warehouse_id

UNION DISTINCT

SELECT
  sa.cs_order_number               AS order_number,
  sa.cp_catalog_page_id            AS catalog_page_id,
  sa.sm_ship_mode_id               AS ship_mode_id,
  sa.w_warehouse_id                AS warehouse_id,
  sa.total_net_profit,
  NULL                             AS total_return_amount,
  i.inv_quantity_on_hand
FROM sales_agg sa
JOIN catalog_page cp
  ON sa.cp_catalog_page_id = cp.cp_catalog_page_id
LEFT JOIN inventory_join i
  ON sa.w_warehouse_id = i.w_warehouse_id
WHERE cp.cp_department = 'Electronics'

ORDER BY order_number DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
