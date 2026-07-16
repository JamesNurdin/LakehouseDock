WITH page_durations AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        sd_start.d_year AS start_year,
        sd_start.d_month_seq AS start_month_seq,
        sd_start.d_date AS start_date,
        sd_end.d_date AS end_date,
        date_diff('day', sd_start.d_date, sd_end.d_date) AS duration_days
    FROM catalog_page cp
    JOIN date_dim sd_start
        ON cp.cp_start_date_sk = sd_start.d_date_sk
    JOIN date_dim sd_end
        ON cp.cp_end_date_sk = sd_end.d_date_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
)
SELECT
    pd.start_year,
    pd.cp_department,
    COUNT(*) AS page_cnt,
    AVG(pd.duration_days) AS avg_duration_days,
    SUM(pd.duration_days) AS total_duration_days,
    RANK() OVER (PARTITION BY pd.start_year ORDER BY COUNT(*) DESC) AS dept_rank,
    CASE
        WHEN COUNT(*) >= 50 THEN 'Heavy'
        WHEN COUNT(*) >= 20 THEN 'Medium'
        ELSE 'Light'
    END AS activity_level
FROM page_durations pd
WHERE pd.start_year BETWEEN 2020 AND 2022
GROUP BY pd.start_year, pd.cp_department
HAVING COUNT(*) > 5
ORDER BY pd.start_year, dept_rank
