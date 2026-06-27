WITH page_durations AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        d_start.d_year,
        d_start.d_moy,
        d_start.d_date AS start_date,
        d_end.d_date AS end_date,
        date_diff('day', d_start.d_date, d_end.d_date) AS duration_days
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE d_start.d_year = 2001
)
SELECT
    pd.cp_department,
    pd.d_year,
    pd.d_moy,
    COUNT(*) AS page_count,
    AVG(pd.duration_days) AS avg_page_duration_days,
    MIN(pd.duration_days) AS min_page_duration_days,
    MAX(pd.duration_days) AS max_page_duration_days
FROM page_durations pd
GROUP BY pd.cp_department, pd.d_year, pd.d_moy
ORDER BY pd.cp_department, pd.d_year, pd.d_moy
