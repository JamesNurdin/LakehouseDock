WITH sales_data AS (
    SELECT
        cp.cp_department AS cp_department,
        td.t_hour AS t_hour,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cp.cp_department = 'DEPARTMENT'
    GROUP BY cp.cp_department, td.t_hour
    HAVING SUM(cs.cs_net_profit) > 0
),
returns_data AS (
    SELECT
        cp.cp_department AS cp_department,
        td.t_hour AS t_hour,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = cr.cr_order_number
          AND cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
    )
    GROUP BY cp.cp_department, td.t_hour
)
SELECT
    department,
    hour,
    source_type,
    metric_value,
    metric_cnt,
    CASE WHEN source_type = 'sale' THEN metric_value ELSE -metric_value END AS signed_metric,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY metric_value DESC) AS dept_metric_rank
FROM (
    SELECT
        cp_department AS department,
        t_hour AS hour,
        'sale' AS source_type,
        total_profit AS metric_value,
        sales_cnt AS metric_cnt
    FROM sales_data
    UNION ALL
    SELECT
        cp_department AS department,
        t_hour AS hour,
        'return' AS source_type,
        total_loss AS metric_value,
        returns_cnt AS metric_cnt
    FROM returns_data
) combined
WHERE metric_value > 100
ORDER BY department, signed_metric DESC
LIMIT 100
