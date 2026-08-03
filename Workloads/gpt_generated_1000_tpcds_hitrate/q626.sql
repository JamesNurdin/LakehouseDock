WITH filtered_warehouses AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_street_name,
        w_city,
        w_state,
        w_warehouse_sq_ft
    FROM warehouse
    WHERE regexp_like(w_street_name, '^\\d{1,2}[a-zA-Z]{2}\\s')      -- e.g., "7th Park"
      AND w_city LIKE '%York%'
)
SELECT
    CONCAT('Warehouse ', SUBSTRING(w.w_warehouse_name, 1, 10)) AS short_name,
    w.w_warehouse_name,
    w.w_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
    CASE
        WHEN w.w_warehouse_sq_ft > 200000 THEN 'Large'
        WHEN w.w_warehouse_sq_ft > 100000 THEN 'Medium'
        ELSE 'Small'
    END AS size_category,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    (SELECT COUNT(*) FROM warehouse WHERE w_state = w.w_state) AS warehouses_in_state
FROM web_sales ws
JOIN filtered_warehouses w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_warehouse_sk IN (
        SELECT w2.w_warehouse_sk
        FROM warehouse w2
        WHERE w2.w_warehouse_name LIKE '%New%'
           OR regexp_like(w2.w_warehouse_name, '^[A-Z][a-z]+')
    )
  AND ws.ws_ext_sales_price > 5000
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = ws.ws_bill_customer_sk
          AND ws2.ws_net_paid_inc_ship_tax > 2000
    )
GROUP BY w.w_warehouse_name, w.w_city, w.w_state, w.w_warehouse_sq_ft
ORDER BY total_sales DESC
LIMIT 100
