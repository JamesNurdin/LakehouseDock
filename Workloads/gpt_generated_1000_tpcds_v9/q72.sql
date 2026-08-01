WITH base_pages AS (
    SELECT
        cp.cp_catalog_page_id AS cp_id,
        cp.cp_type AS page_type,
        cp.cp_department AS dept,
        sd.d_date AS start_date,
        sd.d_year AS start_year,
        sd.d_holiday AS start_holiday,
        ed.d_date AS end_date,
        ed.d_year AS end_year,
        ed.d_holiday AS end_holiday
    FROM catalog_page cp
    JOIN date_dim sd ON cp.cp_start_date_sk = sd.d_date_sk
    JOIN date_dim ed ON cp.cp_end_date_sk = ed.d_date_sk
)
SELECT
    b.cp_id,
    b.page_type,
    b.dept,
    b.start_date,
    b.end_date,
    CASE WHEN b.start_year = b.end_year THEN 'SameYear' ELSE 'CrossYear' END AS year_relation,
    (
        SELECT COUNT(*)
        FROM catalog_page cp2
        WHERE cp2.cp_department = b.dept
    ) AS dept_page_count,
    LAG(b.start_date) OVER (PARTITION BY b.page_type ORDER BY b.start_date) AS prev_start_date
FROM (
    SELECT cp_id, page_type, dept, start_date, end_date, start_year, end_year
    FROM base_pages
    WHERE page_type = 'monthly' AND start_holiday = 'Y'
) AS b
UNION ALL
SELECT
    b2.cp_id,
    b2.page_type,
    b2.dept,
    b2.start_date,
    b2.end_date,
    CASE WHEN b2.start_year = b2.end_year THEN 'SameYear' ELSE 'CrossYear' END AS year_relation,
    (
        SELECT COUNT(*)
        FROM catalog_page cp2
        WHERE cp2.cp_department = b2.dept
    ) AS dept_page_count,
    LAG(b2.start_date) OVER (PARTITION BY b2.page_type ORDER BY b2.start_date) AS prev_start_date
FROM (
    SELECT cp_id, page_type, dept, start_date, end_date, start_year, end_year
    FROM base_pages
    WHERE page_type = 'quarterly' AND end_holiday = 'Y'
) AS b2
ORDER BY page_type, start_date DESC
LIMIT 100
