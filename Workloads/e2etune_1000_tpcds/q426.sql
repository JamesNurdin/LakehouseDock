WITH page_stats AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        COUNT(*) AS page_cnt,
        AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_duration_days,
        SUM(CASE WHEN cp.cp_description LIKE '%public%' THEN 1 ELSE 0 END) AS public_desc_cnt
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
    WHERE d_start.d_fy_year = 2003
      AND cp.cp_type IN ('quarterly', 'monthly')
      AND d_end.d_date >= DATE '2003-01-01'
    GROUP BY cp.cp_department, cp.cp_type
    HAVING COUNT(*) > 5
)
SELECT
    cp_department,
    cp_type,
    page_cnt,
    avg_duration_days,
    public_desc_cnt,
    RANK() OVER (ORDER BY page_cnt DESC) AS dept_type_rank
FROM page_stats
ORDER BY page_cnt DESC
LIMIT 50
