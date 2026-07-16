SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    i.i_category,
    i.i_brand,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    d_sold.d_quarter_name,
    CASE WHEN d_sold.d_weekend = 'Y' THEN 1 ELSE 0 END AS is_weekend,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(CASE WHEN d_sold.d_holiday = 'Y' THEN ss.ss_ext_sales_price ELSE 0 END) AS holiday_sales,
    SUM(CASE WHEN d_sold.d_quarter_name = 'Q1' THEN ss.ss_ext_sales_price ELSE 0 END) AS q1_sales,
    SUM(CASE WHEN d_sold.d_weekend = 'Y' THEN ss.ss_ext_sales_price ELSE 0 END) AS weekend_sales,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    MAX(d_access.d_date) AS latest_page_access,
    MIN(d_closed.d_date) AS store_closed_date,
    (SUM(ss.ss_ext_sales_price) - SUM(ss.ss_ext_discount_amt)) / NULLIF(SUM(ss.ss_quantity), 0) AS avg_net_per_qty,
    SUM(ss.ss_ext_sales_price) / NULLIF(SUM(ss.ss_ext_discount_amt), 0) AS sales_discount_ratio
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    i.i_category,
    i.i_brand,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_quarter_name,
    d_sold.d_weekend
HAVING SUM(ss.ss_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 100
