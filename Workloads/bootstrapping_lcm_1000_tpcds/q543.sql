SELECT 
    s.s_store_name,
    s.s_store_sk,
    d_sold.d_year,
    d_sold.d_month_seq,
    hd.hd_buy_potential,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COALESCE(d_closed.d_year, NULL) AS store_closed_year,
    COUNT(DISTINCT wp_c.wp_web_page_id) AS pages_created_same_day,
    COUNT(DISTINCT wp_a.wp_web_page_id) AS pages_accessed_same_day,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank_by_store
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_page wp_c
    ON wp_c.wp_creation_date_sk = d_sold.d_date_sk
LEFT JOIN web_page wp_a
    ON wp_a.wp_access_date_sk = d_sold.d_date_sk
GROUP BY 
    s.s_store_name,
    s.s_store_sk,
    d_sold.d_year,
    d_sold.d_month_seq,
    hd.hd_buy_potential,
    d_closed.d_year
ORDER BY total_sales DESC
LIMIT 100
