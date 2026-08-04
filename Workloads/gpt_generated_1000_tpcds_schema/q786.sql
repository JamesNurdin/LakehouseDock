WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10) -- sample ~10% of rows
),
joined_with_array AS (
    SELECT
        cs.cs_warehouse_sk,
        w.w_warehouse_name,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cs.cs_ext_tax,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        ARRAY[cs.cs_quantity, CAST(cs.cs_wholesale_cost AS double), cs.cs_ext_tax] AS metrics_arr
    FROM sampled_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450830 AND 2450900
)
,
unnested_metrics AS (
    SELECT
        jd.w_warehouse_name,
        CASE metric_pos
            WHEN 1 THEN 'quantity'
            WHEN 2 THEN 'wholesale_cost'
            WHEN 3 THEN 'tax'
        END AS metric_name,
        metric_value,
        jd.profit_flag
    FROM joined_with_array jd
    CROSS JOIN UNNEST(jd.metrics_arr) WITH ORDINALITY AS t(metric_value, metric_pos)
)
,
aggregated_sales AS (
    SELECT
        w.w_warehouse_name,
        'aggregate' AS metric_name,
        SUM(cs.cs_net_profit) AS metric_value,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM sampled_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450830 AND 2450900
    GROUP BY w.w_warehouse_name
)
SELECT *
FROM unnested_metrics
UNION ALL
SELECT *
FROM aggregated_sales
ORDER BY w_warehouse_name, metric_name
LIMIT 100
