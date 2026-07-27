/*
Goal: Analyze total sales and profitability of catalog sales by call center city, catalog department, carrier, and warehouse state, applying realistic business filters and demonstrating outer‑join handling.
*/
WITH filtered_sales AS (
    SELECT *
    FROM catalog_sales
    WHERE cs_quantity > 0
)
SELECT
    cc.cc_city,
    cp.cp_department,
    sm.sm_carrier,
    COALESCE(w.w_state, 'UNKNOWN') AS warehouse_state,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(cs.cs_order_number) AS order_count,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    CASE
        WHEN AVG(cs.cs_net_profit) >= 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_indicator
FROM filtered_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
    AND w.w_country = 'United States'
WHERE
    cc.cc_city IN ('Cedar Grove', 'Glendale')
    AND cc.cc_mkt_id = 3
    AND sm.sm_carrier = 'FEDEX'
    AND sm.sm_code = 'AIR'
    AND cp.cp_department = 'Electronics'
GROUP BY
    cc.cc_city,
    cp.cp_department,
    sm.sm_carrier,
    COALESCE(w.w_state, 'UNKNOWN')
ORDER BY total_sales DESC
LIMIT 100
