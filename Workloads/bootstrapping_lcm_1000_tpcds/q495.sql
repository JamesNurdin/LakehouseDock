WITH page_stats AS (
    SELECT
        wp.wp_customer_sk AS customer_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS num_pages,
        SUM(wp.wp_char_count) AS total_characters,
        AVG(wp.wp_image_count) AS avg_image_count,
        MAX(wp.wp_max_ad_count) AS max_ad_per_page,
        MAX(wp.wp_creation_date_sk) AS latest_creation_sk,
        MAX(wp.wp_access_date_sk) AS latest_access_sk
    FROM web_page wp
    GROUP BY wp.wp_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    d_shipto.d_date AS shipto_date,
    d_sales.d_date AS first_sales_date,
    d_latest_creation.d_date AS latest_page_creation_date,
    d_latest_access.d_date AS latest_page_access_date,
    s.s_store_name,
    s.s_market_desc,
    d_store_close.d_date AS store_closed_date,
    ps.num_pages,
    ps.total_characters,
    ps.avg_image_count,
    ps.max_ad_per_page
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN page_stats ps ON ps.customer_sk = c.c_customer_sk
JOIN date_dim d_shipto ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_latest_creation ON ps.latest_creation_sk = d_latest_creation.d_date_sk
JOIN date_dim d_latest_access ON ps.latest_access_sk = d_latest_access.d_date_sk
JOIN date_dim d_store_close ON d_store_close.d_date_sk = d_sales.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_store_close.d_date_sk
WHERE d_store_close.d_year = d_sales.d_year
ORDER BY c.c_customer_id
LIMIT 100
