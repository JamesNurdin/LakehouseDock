SELECT
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_quarter_name,
    d_sales.d_month_seq,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(CASE WHEN d_sales.d_weekend = 'Y' THEN ss.ss_ext_sales_price ELSE 0 END) AS weekend_sales,
    SUM(CASE WHEN d_sales.d_weekend = 'N' THEN ss.ss_ext_sales_price ELSE 0 END) AS weekday_sales,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    AVG(date_diff('day', d_creation.d_date, d_access.d_date)) AS avg_page_lifecycle_days,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
        ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
    END AS profit_margin
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE (d_closed.d_date IS NULL OR d_sales.d_date < d_closed.d_date)
  AND d_sales.d_year >= 2015
GROUP BY s.s_store_name, d_sales.d_year, d_sales.d_quarter_name, d_sales.d_month_seq
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
