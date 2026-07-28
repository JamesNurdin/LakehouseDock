WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    CONCAT(cp.cp_catalog_page_id, '-', cp.cp_type) AS page_key,
    sm.sm_carrier,
    REGEXP_EXTRACT(sm.sm_carrier, '([A-Z]{3})') AS carrier_prefix,
    w.w_warehouse_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt
FROM filtered_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE
    REGEXP_LIKE(cp.cp_description, '(?i)limited')
    AND sm.sm_type LIKE 'AIR%'
    AND w.w_warehouse_name LIKE '%East%'
    AND d.d_year = 2001
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
          AND cs2.cs_net_profit > 2000
    )
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    CONCAT(cp.cp_catalog_page_id, '-', cp.cp_type),
    sm.sm_carrier,
    REGEXP_EXTRACT(sm.sm_carrier, '([A-Z]{3})'),
    w.w_warehouse_name
ORDER BY total_sales DESC
LIMIT 100
