SELECT
    d_sales.d_date,
    d_sales.d_year,
    s.s_store_name,
    s.s_state,
    d_closed.d_date AS store_closed_date,
    COALESCE(wp_create.created_pages, 0) AS num_created_pages,
    COALESCE(wp_access.accessed_pages, 0) AS num_accessed_pages,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN (
    SELECT wp_creation_date_sk, COUNT(*) AS created_pages
    FROM web_page
    GROUP BY wp_creation_date_sk
) wp_create
    ON wp_create.wp_creation_date_sk = d_sales.d_date_sk
LEFT JOIN (
    SELECT wp_access_date_sk, COUNT(*) AS accessed_pages
    FROM web_page
    GROUP BY wp_access_date_sk
) wp_access
    ON wp_access.wp_access_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    d_sales.d_date,
    d_sales.d_year,
    s.s_store_name,
    s.s_state,
    d_closed.d_date,
    wp_create.created_pages,
    wp_access.accessed_pages
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
