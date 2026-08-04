WITH
  -- Pre‑aggregate inventory (sampled) to shrink the join size
  inv_agg AS (
    SELECT
      inv_warehouse_sk,
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_warehouse_sk, inv_date_sk
  ),
  -- Pre‑aggregate store sales per customer / date
  sales_agg AS (
    SELECT
      ss_customer_sk,
      ss_sold_date_sk,
      SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_customer_sk, ss_sold_date_sk
  ),
  -- Orders that appear both as a catalog sale and a catalog return for the same department
  order_intersect AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Electronics'
    INTERSECT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    WHERE cp2.cp_department = 'Electronics'
  ),
  -- Union that adds all store‑sales ticket numbers (to guarantee some rows even without returns)
  union_orders AS (
    SELECT order_number FROM order_intersect
    UNION
    SELECT ss_ticket_number AS order_number
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
  )
SELECT DISTINCT
  c.c_customer_id,
  d_sales.d_year,
  w.w_warehouse_name,
  CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category,
  COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
  SUM(inv_agg.total_qty) AS total_inventory_qty,
  SUM(sales_agg.total_profit) AS total_store_profit,
  SUM(cs.cs_net_paid) AS total_net_paid,
  (SELECT COUNT(*) FROM promotion p_sub WHERE p_sub.p_discount_active = 'Y') AS active_promo_count
FROM union_orders u
JOIN catalog_sales cs ON cs.cs_order_number = u.order_number
JOIN catalog_page cp_sales ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv ON inv_agg.inv_date_sk = d_inv.d_date_sk
JOIN sales_agg ON sales_agg.ss_customer_sk = c.c_customer_sk
     AND sales_agg.ss_sold_date_sk = d_sales.d_date_sk
WHERE EXISTS (
  SELECT 1
  FROM catalog_returns cr
  WHERE cr.cr_order_number = cs.cs_order_number
    AND cr.cr_return_quantity > 0
)
GROUP BY CUBE (c.c_customer_id, d_sales.d_year, w.w_warehouse_name)
HAVING COUNT(*) > 5
ORDER BY total_store_profit DESC
LIMIT 100
