WITH warehouse_inventory_sales AS (
   SELECT
      w.w_warehouse_sk,
      w.w_warehouse_id,
      w.w_city,
      w.w_state,
      SUM(i.inv_quantity_on_hand) AS inv_qty,
      SUM(ws.ws_quantity) AS sold_qty,
      SUM(ws.ws_ext_list_price * ws.ws_quantity) AS sales_value,
      AVG(ws.ws_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax
   FROM inventory i
   JOIN warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN web_sales ws
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE i.inv_date_sk BETWEEN 2450800 AND 2451100
     AND i.inv_quantity_on_hand > 0
     AND w.w_country = 'United States'
     AND w.w_warehouse_sq_ft >= 15000
     AND ws.ws_ext_list_price > 1500
     AND ws.ws_net_paid_inc_ship_tax BETWEEN 2000 AND 25000
   GROUP BY
      w.w_warehouse_sk,
      w.w_warehouse_id,
      w.w_city,
      w.w_state
)
SELECT
   w_city,
   w_state,
   COUNT(*) AS warehouse_count,
   SUM(inv_qty) AS total_inventory,
   SUM(sold_qty) AS total_sold,
   SUM(sales_value) AS total_sales,
   AVG(avg_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax_across_warehouses
FROM warehouse_inventory_sales
WHERE inv_qty > 1000
  AND sales_value > 500000
GROUP BY w_city, w_state
HAVING COUNT(*) >= 2
ORDER BY total_sales DESC
LIMIT 5
