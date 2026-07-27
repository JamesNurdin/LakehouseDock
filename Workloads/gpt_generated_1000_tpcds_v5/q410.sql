WITH inv_cte AS (
    SELECT w.w_warehouse_sk,
           SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT DISTINCT warehouse_name,
                total_sales,
                total_inventory
FROM (
    SELECT w.w_warehouse_name AS warehouse_name,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           inv.total_inventory
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inv_cte inv ON w.w_warehouse_sk = inv.w_warehouse_sk
    WHERE wp.wp_type = 'home'
      AND ws.ws_ext_ship_cost > 1000
    GROUP BY w.w_warehouse_name, inv.total_inventory

    UNION ALL

    SELECT w.w_warehouse_name AS warehouse_name,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           inv.total_inventory
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inv_cte inv ON w.w_warehouse_sk = inv.w_warehouse_sk
    WHERE wp.wp_type = 'product'
      AND ws.ws_ext_ship_cost <= 500
    GROUP BY w.w_warehouse_name, inv.total_inventory
) AS combined
ORDER BY total_sales DESC
LIMIT 100
