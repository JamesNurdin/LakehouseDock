WITH ws_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_list_price,
        ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_ext_list_price > 1000
      AND ws.ws_quantity >= 1
      AND ws.ws_net_profit IS NOT NULL
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    cp.cp_department,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_sales_price) AS avg_sales,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFITABLE'
        ELSE 'LOSS'
    END AS profit_status,
    COALESCE(w.w_city, 'UNKNOWN') AS warehouse_city
FROM ws_filtered ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
WHERE d.d_weekend = 'N'
  AND d.d_fy_year = 1912
  AND w.w_street_type = 'Road'
  AND cp.cp_department = 'Electronics'
GROUP BY d.d_year, w.w_warehouse_name, cp.cp_department, w.w_city
ORDER BY total_sales DESC
LIMIT 100
