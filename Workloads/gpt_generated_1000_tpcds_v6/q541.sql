WITH page_counts AS (
    SELECT
        cp.cp_department AS department,
        d_start.d_year AS year,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS page_cnt,
        SUM(cp.cp_catalog_number) AS total_catalog_numbers
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE d_start.d_qoy = 2
      AND d_end.d_holiday = 'N'
      AND cp.cp_catalog_number > 0
      AND cp.cp_type = 'A'
    GROUP BY GROUPING SETS (
        (cp.cp_department, d_start.d_year),
        (cp.cp_department),
        (d_start.d_year)
    )
)
SELECT
    pc.department,
    pc.year,
    pc.page_cnt,
    pc.total_catalog_numbers,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_department = pc.department
              AND cp2.cp_catalog_page_number > 10
        ) THEN 'ACTIVE'
        ELSE 'INACTIVE'
    END AS activity_flag,
    AVG(pc.page_cnt) OVER (PARTITION BY pc.department) AS avg_pages_per_dept
FROM page_counts pc
WHERE pc.page_cnt > 5
  AND pc.total_catalog_numbers > 100
  AND pc.department IS NOT NULL
  AND pc.year IS NOT NULL
ORDER BY pc.department, pc.year
LIMIT 100
