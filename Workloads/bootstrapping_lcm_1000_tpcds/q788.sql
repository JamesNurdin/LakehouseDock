SELECT
    d_cc_closing.d_year AS closed_year,
    d_cc_closing.d_month_seq AS closed_month,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_cnt,
    SUM(cc.cc_employees) AS call_center_employees,
    COUNT(DISTINCT s.s_store_sk) AS store_cnt,
    SUM(s.s_number_employees) AS store_employees,
    CAST(SUM(cc.cc_employees) AS double) / NULLIF(SUM(s.s_number_employees), 0) AS emp_ratio,
    COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_cnt,
    SUM(CASE WHEN wp.wp_type = 'article' THEN 1 ELSE 0 END) AS article_page_cnt,
    SUM(CASE WHEN wp.wp_type = 'advertisement' THEN 1 ELSE 0 END) AS advertisement_page_cnt,
    COUNT(DISTINCT c.c_customer_sk) AS customer_cnt,
    AVG(c.c_birth_year) AS avg_customer_birth_year,
    MIN(d_cc_closing.d_date) AS min_closed_date,
    MAX(d_cc_closing.d_date) AS max_closed_date,
    AVG(date_diff('day', d_cc_open.d_date, d_cc_closing.d_date)) AS avg_days_open_to_close
FROM call_center cc
JOIN date_dim d_cc_closing
    ON cc.cc_closed_date_sk = d_cc_closing.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closing.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cc_closing.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_c_first_sales
    ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
JOIN date_dim d_c_first_shipto
    ON c.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
GROUP BY
    d_cc_closing.d_year,
    d_cc_closing.d_month_seq
HAVING
    COUNT(DISTINCT cc.cc_call_center_sk) > 0
ORDER BY
    closed_year,
    closed_month
LIMIT 100
