WITH sales_with_strings AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_net_paid,
        ss.ss_quantity,
        i.i_brand,
        i.i_product_name AS product_name,
        regexp_extract(i.i_product_name, '(\\d{3})', 1) AS product_code,
        concat(s.s_state, '-', s.s_city) AS store_location,
        c.c_email_address,
        d.d_year,
        s.s_store_name AS store_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
)
SELECT
    store_location,
    i_brand,
    product_code,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers
FROM sales_with_strings
WHERE
    regexp_like(product_name, '\\d{3}')
    AND regexp_like(c_email_address, '@.*\\.com$')
    AND store_name LIKE '%Mall%'
GROUP BY store_location, i_brand, product_code
ORDER BY total_net_paid DESC
LIMIT 100
