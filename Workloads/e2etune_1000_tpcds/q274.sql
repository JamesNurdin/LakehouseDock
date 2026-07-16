WITH catalog_summary AS (
    SELECT
        cp.cp_department,
        cp.cp_start_date_sk,
        cp.cp_type,
        cp.cp_catalog_page_number,
        cp.cp_catalog_number,
        cp.cp_catalog_page_id
    FROM catalog_page cp
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_department IN ('DEPARTMENT1', 'DEPARTMENT2', 'DEPARTMENT3')
),
customer_income AS (
    SELECT
        c.c_customer_sk,
        c.c_first_sales_date_sk,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        (ib.ib_upper_bound - ib.ib_lower_bound) AS ib_range
    FROM customer c
    LEFT JOIN income_band ib
        ON c.c_birth_year BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE c.c_preferred_cust_flag = 'Y'
),
joined_data AS (
    SELECT
        cs.cp_department,
        ci.c_customer_sk,
        cs.cp_catalog_page_number,
        ci.ib_range
    FROM catalog_summary cs
    JOIN customer_income ci
        ON cs.cp_start_date_sk = ci.c_first_sales_date_sk
),
dept_agg AS (
    SELECT
        jd.cp_department,
        COUNT(DISTINCT jd.c_customer_sk) AS num_preferred_customers,
        AVG(jd.cp_catalog_page_number) AS avg_page_number,
        SUM(jd.ib_range) AS total_income_band_range,
        ROUND(SUM(jd.ib_range) * 1.0 / NULLIF(COUNT(DISTINCT jd.c_customer_sk), 0), 2) AS avg_income_band_range_per_customer
    FROM joined_data jd
    GROUP BY jd.cp_department
    HAVING COUNT(DISTINCT jd.c_customer_sk) >= 5
)
SELECT
    da.cp_department,
    da.num_preferred_customers,
    da.avg_page_number,
    da.total_income_band_range,
    da.avg_income_band_range_per_customer,
    RANK() OVER (ORDER BY da.total_income_band_range DESC) AS department_rank
FROM dept_agg da
ORDER BY da.total_income_band_range DESC
LIMIT 5
