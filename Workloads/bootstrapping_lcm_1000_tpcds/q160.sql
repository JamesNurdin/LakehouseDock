SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month,
    cp.cp_type,
    cp.cp_department,
    cp.cp_description,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_ext_sales_price ELSE 0 END) AS high_quantity_sales,
    MIN(d_store.d_date) AS store_closed_date,
    MAX(d_cat_start.d_date) AS catalog_start_date,
    MAX(d_cat_end.d_date) AS catalog_end_date,
    MAX(d_wp_access.d_day_name) AS last_access_day_name,
    COUNT(*) AS sales_transactions
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sales.d_date_sk
JOIN date_dim d_cat_start
    ON cp.cp_start_date_sk = d_cat_start.d_date_sk
JOIN date_dim d_cat_end
    ON cp.cp_end_date_sk = d_cat_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE s.s_state = 'TX'
  AND d_sales.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_sales.d_year,
    d_sales.d_month_seq,
    cp.cp_type,
    cp.cp_department,
    cp.cp_description
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY total_ext_sales DESC
LIMIT 100
