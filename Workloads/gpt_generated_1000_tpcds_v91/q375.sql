WITH dept_year_stats AS (
    SELECT
        cp.cp_department,
        d.d_year,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS page_count,
        SUM(cp.cp_catalog_number) AS total_catalog_number,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        AVG(c.c_birth_day) AS avg_birth_day
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE
        d.d_current_day = 'N'
        AND d.d_qoy = 2
        AND cp.cp_catalog_page_number IN (5, 13, 15)
        AND c.c_birth_day > 15
        AND c.c_last_review_date BETWEEN 2452392 AND 2452633
    GROUP BY
        cp.cp_department,
        d.d_year
)
SELECT
    ds.cp_department,
    AVG(ds.page_count) AS avg_page_count_per_year,
    SUM(ds.distinct_customers) AS total_distinct_customers,
    MAX(ds.total_catalog_number) AS max_total_catalog_number,
    (
        SELECT COUNT(DISTINCT cp2.cp_catalog_page_id)
        FROM tpcds.catalog_page cp2
        WHERE cp2.cp_department = ds.cp_department
    ) AS total_distinct_pages_by_dept
FROM dept_year_stats ds
WHERE ds.total_catalog_number > 0
GROUP BY ds.cp_department
HAVING AVG(ds.page_count) > 5
ORDER BY avg_page_count_per_year DESC
LIMIT 100
