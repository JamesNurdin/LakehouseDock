WITH page_durations AS (
    SELECT cp.cp_catalog_page_id,
           cp.cp_department,
           cp.cp_type,
           cp.cp_catalog_number,
           d_start.d_year AS start_year,
           d_end.d_year AS end_year,
           date_diff('day', d_start.d_date, d_end.d_date) AS duration_days
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND cp.cp_start_date_sk IN (2450815, 2450997, 2450906)
      AND d_start.d_year BETWEEN 2020 AND 2022
)
SELECT pd.cp_department,
       pd.cp_type,
       COUNT(*) AS page_count,
       AVG(pd.duration_days) AS avg_page_duration,
       SUM(CASE WHEN pd.cp_catalog_number = 1 THEN 1 ELSE 0 END) AS catalog_1_pages,
       RANK() OVER (ORDER BY AVG(pd.duration_days) DESC) AS duration_rank
FROM page_durations pd
GROUP BY pd.cp_department, pd.cp_type
HAVING COUNT(*) >= 5
ORDER BY avg_page_duration DESC
LIMIT 20
