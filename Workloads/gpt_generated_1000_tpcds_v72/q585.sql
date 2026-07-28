WITH page_site_agg AS (
    SELECT
        ws.web_site_id,
        ws.web_state,
        cp.cp_department,
        d_start.d_year AS start_year,
        COUNT(cp.cp_catalog_page_sk) AS page_count,
        SUM(cp.cp_catalog_number) AS total_catalog_number
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_start.d_date_sk
    WHERE
        d_start.d_year BETWEEN 2000 AND 2001
        AND d_end.d_year BETWEEN 2000 AND 2001
        AND ws.web_state = 'CA'
        AND ws.web_class = 'Unknown'
        AND cp.cp_type = 'A'
        AND cp.cp_department IS NOT NULL
    GROUP BY
        ws.web_site_id,
        ws.web_state,
        cp.cp_department,
        d_start.d_year
),
dept_agg AS (
    SELECT
        cp_department,
        SUM(total_catalog_number) AS dept_total_catalog,
        AVG(page_count) AS dept_avg_page_count
    FROM page_site_agg
    GROUP BY cp_department
)
SELECT
    psa.web_site_id,
    psa.web_state,
    psa.cp_department,
    psa.start_year,
    psa.page_count,
    psa.total_catalog_number,
    da.dept_total_catalog,
    da.dept_avg_page_count,
    (psa.total_catalog_number / da.dept_total_catalog) AS pct_of_dept_total,
    RANK() OVER (ORDER BY psa.total_catalog_number DESC) AS site_rank,
    SUM(psa.total_catalog_number) OVER (PARTITION BY psa.cp_department) AS sum_by_dept_window
FROM page_site_agg psa
JOIN dept_agg da
    ON psa.cp_department = da.cp_department
WHERE
    psa.total_catalog_number > 500
    AND da.dept_total_catalog > 2000
ORDER BY psa.total_catalog_number DESC, psa.web_site_id
LIMIT 100
