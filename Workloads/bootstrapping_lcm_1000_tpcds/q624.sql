SELECT
    s.s_store_id                                            AS store_id,
    s.s_store_name                                          AS store_name,
    d_sales.d_year                                          AS sales_year,
    d_sales.d_month_seq                                     AS sales_month,
    COUNT(DISTINCT ss.ss_customer_sk)                       AS unique_customers,
    SUM(ss.ss_ext_sales_price)                              AS total_sales_amount,
    SUM(ss.ss_net_profit)                                   AS total_profit,
    AVG(ss.ss_quantity)                                     AS avg_quantity_sold,
    COUNT(DISTINCT wp.wp_web_page_id)                       AS total_web_pages_viewed,
    SUM(CASE 
            WHEN d_wp_creation.d_year = d_sales.d_year
                 AND d_wp_creation.d_month_seq = d_sales.d_month_seq
            THEN 1 ELSE 0 END)                              AS web_pages_created_this_month,
    SUM(CASE 
            WHEN d_wp_access.d_year = d_sales.d_year
                 AND d_wp_access.d_month_seq = d_sales.d_month_seq
            THEN 1 ELSE 0 END)                              AS web_pages_accessed_this_month,
    MIN(d_close.d_date)                                     AS store_closed_date,
    MIN(d_c_first_sales.d_date)                             AS earliest_customer_first_sales_date,
    MAX(d_c_first_shipto.d_date)                            AS latest_customer_first_shipto_date
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_close
    ON s.s_closed_date_sk = d_close.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
LEFT JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LEFT JOIN date_dim d_c_first_sales
    ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
LEFT JOIN date_dim d_c_first_shipto
    ON c.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq
ORDER BY total_sales_amount DESC, total_profit DESC
LIMIT 100
