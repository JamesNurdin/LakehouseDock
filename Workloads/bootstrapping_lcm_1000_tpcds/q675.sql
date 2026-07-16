SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    COUNT(DISTINCT wp.wp_web_page_id) AS unique_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(CASE WHEN d_sales.d_quarter_seq = 1 THEN ss.ss_ext_sales_price ELSE 0 END) AS q1_sales,
    SUM(CASE WHEN d_sales.d_quarter_seq = 2 THEN ss.ss_ext_sales_price ELSE 0 END) AS q2_sales,
    SUM(CASE WHEN d_sales.d_quarter_seq = 3 THEN ss.ss_ext_sales_price ELSE 0 END) AS q3_sales,
    SUM(CASE WHEN d_sales.d_quarter_seq = 4 THEN ss.ss_ext_sales_price ELSE 0 END) AS q4_sales,
    MIN(d_sales.d_date) AS first_sale_date,
    MAX(d_sales.d_date) AS last_sale_date,
    SUM(CASE WHEN wp.wp_type = 'home' THEN wp.wp_image_count ELSE 0 END) AS home_page_images,
    SUM(CASE WHEN wp.wp_type = 'product' THEN wp.wp_image_count ELSE 0 END) AS product_page_images,
    AVG(date_diff('day', d_c_first_sales.d_date, d_sales.d_date)) AS avg_days_since_first_sale,
    AVG(date_diff('day', d_c_first_shipto.d_date, d_sales.d_date)) AS avg_days_since_first_shipto
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_c_first_shipto
    ON c.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
JOIN date_dim d_c_first_sales
    ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
WHERE (s.s_closed_date_sk IS NULL OR d_store_closed.d_date > d_sales.d_date)
  AND d_sales.d_year BETWEEN 2015 AND 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY total_ext_sales DESC
LIMIT 50
