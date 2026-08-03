/*
Goal: Analyze catalog page activity by fiscal year, categorize by page type, and examine the distribution of page count vs. total catalog number metrics.
The query joins catalog_page to date_dim, aggregates per page and year, builds an array of metrics, unnests it, and then performs a second level aggregation with a HAVING filter.
*/
WITH agg AS (
    SELECT
        cp.cp_catalog_page_id,
        dd.d_year,
        dd.d_fy_week_seq,
        COUNT(*) AS page_cnt,
        SUM(cp.cp_catalog_number) AS total_catalog_number,
        CASE WHEN cp.cp_type = 'A' THEN 'A' ELSE 'Other' END AS type_category
    FROM catalog_page cp
    JOIN date_dim dd
        ON cp.cp_end_date_sk = dd.d_date_sk
    WHERE
        cp.cp_catalog_number >= 1
        AND cp.cp_catalog_number <= 20
        AND cp.cp_catalog_page_number > 5
        AND dd.d_fy_week_seq IN (2, 4, 5, 7)
        AND dd.d_current_day = 'N'
    GROUP BY
        cp.cp_catalog_page_id,
        dd.d_year,
        dd.d_fy_week_seq,
        CASE WHEN cp.cp_type = 'A' THEN 'A' ELSE 'Other' END
),
expanded AS (
    SELECT
        a.d_year,
        a.page_cnt,
        a.total_catalog_number,
        a.type_category,
        ARRAY[a.page_cnt, a.total_catalog_number] AS metrics
    FROM agg a
),
unnested AS (
    SELECT
        e.d_year,
        e.type_category,
        m AS metric_value,
        CASE WHEN m = e.page_cnt THEN 'page_cnt' ELSE 'total_catalog_number' END AS metric_name
    FROM expanded e
    CROSS JOIN UNNEST(e.metrics) AS t(m)
)
SELECT
    u.d_year,
    u.type_category,
    COUNT(*) FILTER (WHERE u.metric_name = 'page_cnt') AS cnt_page_cnt,
    COUNT(*) FILTER (WHERE u.metric_name = 'total_catalog_number') AS cnt_total,
    AVG(u.metric_value) FILTER (WHERE u.metric_name = 'total_catalog_number') AS avg_total_metric
FROM unnested u
GROUP BY
    u.d_year,
    u.type_category
HAVING
    AVG(u.metric_value) FILTER (WHERE u.metric_name = 'total_catalog_number') > 5
ORDER BY
    u.d_year DESC,
    u.type_category
LIMIT 100
