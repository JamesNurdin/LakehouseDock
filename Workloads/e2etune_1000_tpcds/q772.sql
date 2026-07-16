WITH cc_agg AS (
    SELECT
        d_open.d_year AS year,
        cc.cc_class,
        COUNT(DISTINCT cc.cc_call_center_sk) AS cc_cnt,
        AVG(cc.cc_employees) AS avg_employees,
        AVG(cc.cc_gmt_offset) AS avg_gmt_offset,
        AVG(date_diff('day', d_open.d_date, d_close.d_date)) AS avg_lifespan_days
    FROM call_center cc
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON cc.cc_closed_date_sk = d_close.d_date_sk
    WHERE cc.cc_class IN ('large', 'medium')
    GROUP BY d_open.d_year, cc.cc_class
),
cp_agg AS (
    SELECT
        d_start.d_year AS year,
        cp.cp_type,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS cp_cnt
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    WHERE cp.cp_type IS NOT NULL
    GROUP BY d_start.d_year, cp.cp_type
),
cust_agg AS (
    SELECT
        d_sales.d_year AS year,
        COUNT(DISTINCT cu.c_customer_sk) AS cust_cnt
    FROM customer cu
    JOIN date_dim d_sales ON cu.c_first_sales_date_sk = d_sales.d_date_sk
    GROUP BY d_sales.d_year
)
SELECT
    cc.year,
    cc.cc_class,
    cc.cc_cnt,
    cc.avg_employees,
    cc.avg_gmt_offset,
    cc.avg_lifespan_days,
    cp.cp_type,
    cp.cp_cnt,
    cust.cust_cnt,
    CASE WHEN cp.cp_cnt > 0 THEN cc.avg_employees / cp.cp_cnt ELSE NULL END AS emp_per_page
FROM cc_agg cc
LEFT JOIN cp_agg cp ON cc.year = cp.year
LEFT JOIN cust_agg cust ON cc.year = cust.year
WHERE cc.year BETWEEN 2000 AND 2005
ORDER BY cc.year, cc.cc_class
