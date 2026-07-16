WITH page_durations AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        start_d.d_date AS start_date,
        end_d.d_date AS end_date,
        date_diff('day', start_d.d_date, end_d.d_date) AS duration_days,
        start_d.d_year AS start_year
    FROM catalog_page cp
    JOIN date_dim start_d ON cp.cp_start_date_sk = start_d.d_date_sk
    JOIN date_dim end_d ON cp.cp_end_date_sk = end_d.d_date_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND cp.cp_department = 'DEPARTMENT'
      AND start_d.d_year BETWEEN 2020 AND 2023
)
SELECT
    cp_department AS department,
    cp_type AS catalog_type,
    COUNT(*) AS total_pages,
    AVG(duration_days) AS avg_duration_days,
    SUM(CASE WHEN start_year = 2022 THEN 1 ELSE 0 END) AS pages_started_2022,
    RANK() OVER (ORDER BY AVG(duration_days) DESC) AS duration_rank,
    SUM(COUNT(*)) OVER (ORDER BY AVG(duration_days) DESC) AS cumulative_pages
FROM page_durations
GROUP BY cp_department, cp_type
HAVING COUNT(*) >= 3
ORDER BY avg_duration_days DESC
LIMIT 20
