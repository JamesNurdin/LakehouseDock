SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    CONCAT(CAST(d_sales.d_year AS VARCHAR), '-', LPAD(CAST(d_sales.d_month_seq AS VARCHAR), 2, '0')) AS year_month,
    CASE
        WHEN d_sales.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sales.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sales.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    s.s_state,
    s.s_city,
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT ss.ss_customer_sk) AS num_customers,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(ss.ss_ext_tax) AS total_tax,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages,
    COUNT(DISTINCT CASE WHEN wp.wp_type = 'Product' THEN wp.wp_web_page_sk END) AS num_product_pages,
    SUM(CASE WHEN wp.wp_type = 'Product' THEN 1 ELSE 0 END) AS product_page_events,
    AVG(CASE WHEN wp.wp_type = 'Product' THEN wp.wp_image_count END) AS avg_image_count_product_pages,
    MIN(d_sales.d_date) AS min_sale_date,
    MAX(d_sales.d_date) AS max_sale_date
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sales.d_year BETWEEN 2015 AND 2020
    AND s.s_state = 'CA'
    AND wp.wp_type IS NOT NULL
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    CONCAT(CAST(d_sales.d_year AS VARCHAR), '-', LPAD(CAST(d_sales.d_month_seq AS VARCHAR), 2, '0')),
    CASE
        WHEN d_sales.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sales.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sales.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    s.s_state,
    s.s_city,
    ca.ca_state,
    ca.ca_city
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
