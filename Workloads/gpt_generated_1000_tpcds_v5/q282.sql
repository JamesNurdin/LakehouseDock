WITH sales_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        sm.sm_carrier,
        w.w_warehouse_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_department IN ('Books', 'Electronics', 'Clothing')
      AND cp.cp_type = 'Online'
      AND sm.sm_carrier = 'USPS'
      AND sm.sm_contract LIKE 'I3u%'
      AND w.w_country = 'United States'
      AND cs.cs_quantity > 1
    GROUP BY cp.cp_department, cp.cp_type, sm.sm_carrier, w.w_warehouse_name
)
SELECT
    cp_department AS department,
    cp_type AS type,
    sm_carrier AS carrier,
    w_warehouse_name AS warehouse_name,
    SUM(total_sales) AS sum_sales,
    SUM(total_profit) AS sum_profit,
    SUM(order_cnt) AS sum_orders,
    SUM(total_sales) / NULLIF(SUM(order_cnt), 0) AS avg_sales_per_order,
    SUM(total_profit) / NULLIF(SUM(order_cnt), 0) AS avg_profit_per_order
FROM sales_agg
WHERE total_sales > 10000
GROUP BY GROUPING SETS (
    (cp_department, cp_type, sm_carrier, w_warehouse_name),
    (cp_department, cp_type, sm_carrier),
    (cp_department, cp_type),
    (cp_department),
    ()
)
ORDER BY
    CASE WHEN GROUPING(cp_department) = 0 THEN cp_department ELSE 'ZZZ' END,
    CASE WHEN GROUPING(cp_type) = 0 THEN cp_type ELSE 'ZZZ' END,
    CASE WHEN GROUPING(sm_carrier) = 0 THEN sm_carrier ELSE 'ZZZ' END,
    CASE WHEN GROUPING(w_warehouse_name) = 0 THEN w_warehouse_name ELSE 'ZZZ' END
LIMIT 100
