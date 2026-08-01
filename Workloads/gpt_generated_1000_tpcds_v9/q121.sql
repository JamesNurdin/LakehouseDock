WITH sales_union AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT
        NULL AS warehouse_sk,
        ss.ss_sold_time_sk AS sold_time_sk,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
),

sales_enriched AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        w.w_warehouse_id AS warehouse_id,
        t.t_hour AS hour,
        t.t_minute AS minute,
        CONCAT(CAST(t.t_hour AS VARCHAR), ':', LPAD(CAST(t.t_minute AS VARCHAR), 2, '0')) AS hour_minute,
        SUBSTR(w.w_warehouse_id, 1, 3) AS w_id_prefix,
        CASE WHEN REGEXP_LIKE(t.t_time_id, '^A{8}M') THEN 'MorningPattern' ELSE 'OtherPattern' END AS time_pattern,
        CASE WHEN w.w_warehouse_name LIKE '%WARE%' THEN 'ContainsWARE' ELSE 'Other' END AS warehouse_category,
        s.net_profit
    FROM sales_union s
    LEFT JOIN warehouse w ON s.warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON s.sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(t.t_time_id, '^A{8}[MA]')
)

SELECT
    COALESCE(warehouse_name, 'All Warehouses') AS warehouse_name,
    COALESCE(CAST(hour AS VARCHAR), 'All Hours') AS hour,
    time_pattern,
    warehouse_category,
    hour_minute,
    w_id_prefix,
    SUM(net_profit) AS total_net_profit,
    CASE
        WHEN SUM(net_profit) > 10000 THEN 'High'
        WHEN SUM(net_profit) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_bucket
FROM sales_enriched
GROUP BY ROLLUP(warehouse_name, hour, time_pattern, warehouse_category, hour_minute, w_id_prefix)
ORDER BY
    CASE WHEN warehouse_name IS NULL THEN 1 ELSE 0 END,
    warehouse_name,
    hour,
    time_pattern,
    warehouse_category,
    hour_minute,
    w_id_prefix
LIMIT 100
