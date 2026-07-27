WITH joined AS (
    SELECT
        cp.cp_catalog_page_sk AS cp_catalog_page_sk,
        cp.cp_department AS cp_department,
        cp.cp_type AS cp_type,
        cp.cp_description AS cp_description,
        c.c_birth_year AS c_birth_year,
        d_start.d_year AS start_year,
        d_end.d_year AS end_year,
        d_sales.d_year AS sales_year,
        d_sales.d_current_week AS sales_current_week
    FROM date_dim d_sales
    JOIN customer c
        ON c.c_first_sales_date_sk = d_sales.d_date_sk
    JOIN catalog_page cp
        ON TRUE
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE cp.cp_department IN ('Health', 'Sports')
      AND cp.cp_type = 'A'
      AND c.c_birth_year BETWEEN 1975 AND 1985
      AND d_start.d_year = 2001
      AND d_end.d_year = 2002
      AND d_sales.d_current_week = 'N'
),
agg1 AS (
    SELECT
        cp_department,
        c_birth_year,
        COUNT(DISTINCT cp_catalog_page_sk) AS pages_per_birthyear,
        SUM(LENGTH(cp_description)) AS total_desc_len
    FROM joined
    GROUP BY cp_department, c_birth_year
)
SELECT
    cp_department,
    AVG(pages_per_birthyear) AS avg_pages_per_birthyear,
    AVG(total_desc_len) AS avg_desc_len
FROM agg1
GROUP BY cp_department
HAVING AVG(pages_per_birthyear) > 1
ORDER BY avg_pages_per_birthyear DESC, cp_department
LIMIT 100
