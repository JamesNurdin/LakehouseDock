WITH page_dates AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_description,
        cp.cp_type,
        sd.d_date AS start_date,
        ed.d_date AS end_date,
        sd.d_year AS start_year,
        ed.d_year AS end_year
    FROM catalog_page cp
    LEFT JOIN date_dim sd ON cp.cp_start_date_sk = sd.d_date_sk
    LEFT JOIN date_dim ed ON cp.cp_end_date_sk = ed.d_date_sk
),
dept_stats AS (
    SELECT
        cp_department,
        start_year,
        COUNT(*) AS pages_started,
        SUM(CASE WHEN end_year = start_year THEN 1 ELSE 0 END) AS pages_ended_same_year,
        AVG(cp_catalog_page_number) AS avg_page_number
    FROM page_dates
    WHERE start_date >= DATE '2022-01-01'
      AND start_date < DATE '2023-01-01'
    GROUP BY cp_department, start_year
)
SELECT
    cp_department,
    start_year,
    pages_started,
    pages_ended_same_year,
    avg_page_number,
    RANK() OVER (ORDER BY pages_started DESC) AS department_rank
FROM dept_stats
ORDER BY pages_started DESC
