WITH page_stats AS (
    SELECT
        cp.cp_department,
        d_start.d_year AS start_year,
        COUNT(*) AS page_count,
        AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_duration_days,
        AVG(cp.cp_catalog_page_number) AS avg_page_number
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE cp.cp_type = 'quarterly'
      AND cp.cp_department IS NOT NULL
    GROUP BY cp.cp_department, d_start.d_year
)
SELECT
    cp_department,
    start_year,
    page_count,
    avg_duration_days,
    avg_page_number,
    RANK() OVER (ORDER BY page_count DESC) AS year_rank
FROM page_stats
ORDER BY page_count DESC, start_year
