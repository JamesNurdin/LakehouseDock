SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    t.t_am_pm,
    wp.wp_type,
    CASE
        WHEN d_sold.d_month_seq BETWEEN 1 AND 3 THEN 'Jan-Mar'
        WHEN d_sold.d_month_seq BETWEEN 4 AND 6 THEN 'Apr-Jun'
        WHEN d_sold.d_month_seq BETWEEN 7 AND 9 THEN 'Jul-Sep'
        ELSE 'Oct-Dec'
    END AS month_quarter,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(wp.wp_image_count, 0)) AS total_images,
    SUM(COALESCE(wp.wp_link_count, 0)) AS total_links,
    MAX(d_closed.d_date) AS store_closed_date
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_closed_date_sk IS NULL
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    t.t_am_pm,
    wp.wp_type,
    CASE
        WHEN d_sold.d_month_seq BETWEEN 1 AND 3 THEN 'Jan-Mar'
        WHEN d_sold.d_month_seq BETWEEN 4 AND 6 THEN 'Apr-Jun'
        WHEN d_sold.d_month_seq BETWEEN 7 AND 9 THEN 'Jul-Sep'
        ELSE 'Oct-Dec'
    END
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
