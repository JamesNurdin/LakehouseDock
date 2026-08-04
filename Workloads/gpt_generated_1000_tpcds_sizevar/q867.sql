WITH sales_agg AS (
    SELECT
        cp.cp_department AS department,
        SUM(cs.cs_net_paid) AS total_sales_net,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_department
),
returns_agg AS (
    SELECT
        cp.cp_department AS department,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_department
),
union_all AS (
    SELECT department, total_sales_net AS metric, 'sales'   AS metric_type FROM sales_agg
    UNION
    SELECT department, total_return_amount AS metric, 'returns' AS metric_type FROM returns_agg
),
common_depts AS (
    SELECT department FROM sales_agg
    INTERSECT
    SELECT department FROM returns_agg
),
final AS (
    SELECT
        u.department,
        u.metric_type,
        SUM(u.metric) AS total_metric,
        (
            SELECT COUNT(DISTINCT cs3.cs_bill_customer_sk)
            FROM catalog_sales cs3
            JOIN catalog_page cp3 ON cs3.cs_catalog_page_sk = cp3.cp_catalog_page_sk
            WHERE cp3.cp_department = u.department
        ) AS distinct_customer_cnt
    FROM union_all u
    WHERE u.department IN (SELECT department FROM common_depts)
    GROUP BY ROLLUP (u.department, u.metric_type)
)
SELECT
    department,
    metric_type,
    total_metric,
    distinct_customer_cnt
FROM final
ORDER BY department NULLS LAST, metric_type
LIMIT 100
