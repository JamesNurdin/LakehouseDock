WITH sales_by_warehouse AS (
   SELECT
       cs.cs_warehouse_sk,
       sum(cs.cs_ext_sales_price) AS total_sales,
       sum(cs.cs_net_profit)   AS total_profit,
       count(*)                AS order_cnt
   FROM catalog_sales cs
   GROUP BY cs.cs_warehouse_sk
),
inventory_by_warehouse AS (
   SELECT
       inv.inv_warehouse_sk,
       sum(inv.inv_quantity_on_hand) AS total_inventory_qty
   FROM inventory inv
   GROUP BY inv.inv_warehouse_sk
),
warehouse_info AS (
   SELECT
       w.w_warehouse_sk,
       w.w_warehouse_name,
       w.w_city,
       w.w_state
   FROM warehouse w
)
SELECT
   wi.w_warehouse_name,
   wi.w_city,
   wi.w_state,
   coalesce(s.total_sales, 0)        AS total_sales,
   coalesce(s.total_profit, 0)       AS total_profit,
   coalesce(s.order_cnt, 0)          AS order_cnt,
   coalesce(i.total_inventory_qty, 0) AS total_inventory_qty
FROM warehouse_info wi
LEFT JOIN sales_by_warehouse s
  ON wi.w_warehouse_sk = s.cs_warehouse_sk
LEFT JOIN inventory_by_warehouse i
  ON wi.w_warehouse_sk = i.inv_warehouse_sk
ORDER BY total_sales DESC
