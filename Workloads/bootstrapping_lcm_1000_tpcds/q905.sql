SELECT
    s.s_city,
    s.s_store_name,
    s.s_state,
    d_store.d_year,
    d_store.d_quarter_name,
    DATE_TRUNC('month', d_store.d_date) AS month,
    c.c_birth_year - (c.c_birth_year % 10) AS birth_decade,
    COUNT(*) AS total_web_pages,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(wp.wp_image_count) AS total_image_count,
    AVG(wp.wp_image_count) AS avg_image_per_page,
    SUM(wp.wp_char_count) AS total_char_count,
    AVG(DATE_DIFF('day', d_store.d_date, d_access.d_date)) AS avg_days_between_creation_and_access,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers_count,
    SUM(s.s_tax_percentage) AS total_tax_percentage_sum,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customer_ids
FROM store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_store.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_shipto ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review ON c.c_last_review_date = d_review.d_date_sk
WHERE s.s_country = 'United States'
GROUP BY
    s.s_city,
    s.s_store_name,
    s.s_state,
    d_store.d_year,
    d_store.d_quarter_name,
    DATE_TRUNC('month', d_store.d_date),
    c.c_birth_year - (c.c_birth_year % 10)
ORDER BY
    s.s_city,
    d_store.d_year,
    month
LIMIT 100
