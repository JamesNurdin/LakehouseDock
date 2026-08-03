/*
Goal: Compare warehouse performance by total sales amount and total quantity sold, labeling high‑performing warehouses, while demonstrating scalar subqueries, EXISTS filters, CASE logic, and a UNION of two analytical result sets.
*/
WITH sales_metrics AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        CAST(SUM(ws.ws_ext_sales_price) AS double) AS metric,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS label
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450822 AND 2451074
      AND ws.ws_ext_sales_price > (
          SELECT MAX(ws2.ws_ext_sales_price)
          FROM web_sales ws2
          WHERE ws2.ws_sold_date_sk = 2451053
      )
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_item_sk = ws.ws_item_sk
            AND i2.inv_quantity_on_hand > 0
      )
    GROUP BY w.w_warehouse_id, w.w_city
),
quantity_metrics AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        CAST(SUM(ws.ws_quantity) AS double) AS metric,
        CASE WHEN SUM(ws.ws_quantity) > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS label
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450822 AND 2451074
      AND ws.ws_quantity > (
          SELECT AVG(ws2.ws_quantity)
          FROM web_sales ws2
      )
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_item_sk = ws.ws_item_sk
            AND i2.inv_quantity_on_hand > 5
      )
    GROUP BY w.w_warehouse_id, w.w_city
)
SELECT *
FROM (
    SELECT w_warehouse_id, w_city, metric, label FROM sales_metrics
    UNION
    SELECT w_warehouse_id, w_city, metric, label FROM quantity_metrics
) AS combined
ORDER BY metric DESC
LIMIT 100
