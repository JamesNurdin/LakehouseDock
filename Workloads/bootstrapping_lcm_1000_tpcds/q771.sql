SELECT
    s.s_division_name AS division,
    ws.web_mkt_desc AS market_desc,
    d0.d_year AS common_year,
    CASE WHEN d0.d_moy % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    COUNT(*) AS total_pages,
    SUM(wp.wp_image_count) AS total_images,
    SUM(CASE WHEN wp.wp_image_count > 15 THEN wp.wp_image_count ELSE 0 END) AS high_image_sum,
    AVG(wp.wp_link_count) AS avg_links,
    MIN(d0.d_date) AS min_common_date,
    MAX(d_ws_close.d_date) AS max_ws_close_date,
    DATE_DIFF('day', MIN(d0.d_date), MAX(d_ws_close.d_date)) AS store_to_ws_close_days
FROM
    date_dim d0
    JOIN store s ON s.s_closed_date_sk = d0.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = d0.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d0.d_date_sk
    JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE
    d_wp_access.d_date BETWEEN d0.d_date AND DATE_ADD('day', 90, d0.d_date)
    AND s.s_number_employees > 100
GROUP BY
    s.s_division_name,
    ws.web_mkt_desc,
    d0.d_year,
    CASE WHEN d0.d_moy % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING
    COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY
    total_images DESC
LIMIT 100
