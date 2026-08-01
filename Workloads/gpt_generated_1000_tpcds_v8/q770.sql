WITH orders_common AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
    INTERSECT
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_ship_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
),
filtered_sales AS (
    SELECT cs.cs_order_number,
           cs.cs_sold_date_sk,
           cs.cs_ext_sales_price,
           cs.cs_quantity,
           cs.cs_warehouse_sk,
           cs.cs_ship_mode_sk,
           cs.cs_catalog_page_sk,
           cs.cs_net_profit,
           d.d_date,
           sm.sm_type,
           w.w_warehouse_name
    FROM catalog_sales cs
    JOIN orders_common oc ON cs.cs_order_number = oc.cs_order_number
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND regexp_like(d.d_day_name, '^S')
),
page_info AS (
    SELECT cp.cp_catalog_page_sk,
           cp.cp_type,
           cp.cp_description,
           cp.cp_catalog_number,
           CASE WHEN cp.cp_type = 'monthly' THEN 'M'
                WHEN cp.cp_type = 'quarterly' THEN 'Q'
                ELSE 'O' END AS type_flag
    FROM catalog_page cp
    WHERE cp.cp_description LIKE '%sale%'
      AND regexp_extract(cp.cp_description, '(\\d+)%', 1) IS NOT NULL
)
SELECT
    fs.cs_order_number,
    pi.type_flag,
    pi.cp_description,
    CONCAT(pi.cp_type, '-', CAST(pi.cp_catalog_number AS varchar)) AS catalog_label,
    fs.cs_ext_sales_price,
    SUM(fs.cs_ext_sales_price) OVER (PARTITION BY fs.cs_warehouse_sk ORDER BY fs.cs_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales,
    LAG(fs.cs_ext_sales_price) OVER (PARTITION BY fs.cs_warehouse_sk ORDER BY fs.cs_sold_date_sk) AS prev_sales,
    CASE WHEN sm.sm_type = 'OVERNIGHT' THEN 'Fast' ELSE 'Regular' END AS ship_speed,
    (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_warehouse_sk = fs.cs_warehouse_sk) AS warehouse_sales_cnt,
    fs.w_warehouse_name
FROM filtered_sales fs
FULL OUTER JOIN page_info pi ON fs.cs_catalog_page_sk = pi.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE (fs.cs_ext_sales_price > 1000 OR pi.type_flag = 'M')
ORDER BY fs.cs_sold_date_sk DESC
OFFSET 0 LIMIT 100
