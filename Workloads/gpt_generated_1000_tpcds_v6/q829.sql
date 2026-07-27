WITH sales_agg AS (
   SELECT
       w.w_warehouse_name,
       SUM(ws.ws_net_profit) AS total_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
   GROUP BY w.w_warehouse_name
),
sales_rank AS (
   SELECT
       'sales' AS source_type,
       w_warehouse_name,
       total_profit AS metric,
       ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_profit DESC) AS rank,
       SUM(total_profit) OVER () AS window_total
   FROM sales_agg
),
inventory_agg AS (
   SELECT
       w.w_warehouse_name,
       SUM(inv.inv_quantity_on_hand) AS total_qty
   FROM inventory inv
   JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_date = DATE '2001-01-01'
   GROUP BY w.w_warehouse_name
),
inventory_final AS (
   SELECT
       'inventory' AS source_type,
       w_warehouse_name,
       CAST(total_qty AS decimal(10,2)) AS metric,
       CAST(NULL AS integer) AS rank,
       SUM(CAST(total_qty AS decimal(10,2))) OVER () AS window_total
   FROM inventory_agg
)
SELECT *
FROM sales_rank
UNION ALL
SELECT *
FROM inventory_final
LIMIT 100
