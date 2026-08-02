WITH store_metrics AS (
    SELECT s.s_store_id AS entity_id,
           d.d_year AS year,
           SUM(ss.ss_net_profit) AS metric_value
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, d.d_year
),
catalog_return_metrics AS (
    SELECT cp.cp_catalog_page_id AS entity_id,
           d.d_year AS year,
           SUM(cr.cr_return_amount) AS metric_value
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cp.cp_catalog_page_id, d.d_year
),
union_all_metrics AS (
    SELECT 'store' AS entity_type, entity_id, year, metric_value FROM store_metrics
    UNION ALL
    SELECT 'catalog' AS entity_type, entity_id, year, metric_value FROM catalog_return_metrics
)
SELECT
    u.entity_type,
    u.entity_id,
    u.year,
    u.metric_value,
    ROW_NUMBER() OVER (PARTITION BY u.entity_type ORDER BY u.metric_value DESC) AS rank_in_type,
    SUM(u.metric_value) OVER (
        PARTITION BY u.entity_type 
        ORDER BY u.metric_value 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_metric,
    CASE WHEN u.metric_value > (SELECT MAX(metric_value) FROM union_all_metrics) THEN 'TopOverall' ELSE 'Other' END AS overall_category,
    CASE WHEN EXISTS (
        SELECT 1
        FROM store_metrics sm
        WHERE sm.year = u.year
          AND sm.metric_value > u.metric_value
    ) THEN 'HasHigherStore' ELSE 'HighestStoreOrCatalog' END AS higher_store_flag,
    CASE WHEN u.metric_value > (
        SELECT AVG(u2.metric_value)
        FROM union_all_metrics u2
        WHERE u2.year = u.year
    ) THEN 1 ELSE 0 END AS above_year_avg_flag
FROM union_all_metrics u
WHERE u.year > (
    SELECT MAX(d_year)
    FROM (
        SELECT d_year
        FROM date_dim
        WHERE d_month_seq = 1
    ) AS sub
) - 5
ORDER BY u.year DESC, u.metric_value DESC
LIMIT 100
