SELECT
    (d_sales.d_year * 100 + d_sales.d_month_seq) AS year_month,
    CASE WHEN s.s_state = 'CA' THEN 'California' ELSE s.s_state END AS state_group,
    cc.cc_country,
    ws.web_country,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_sales_price) AS avg_sales,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 0 THEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price) ELSE 0 END AS profit_margin,
    COUNT(DISTINCT s.s_store_id) AS num_stores,
    COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
    COUNT(DISTINCT ws.web_site_id) AS num_web_sites,
    MIN(d_sales.d_date) AS first_sale_date,
    MAX(d_sales.d_date) AS last_sale_date,
    SUM(CASE WHEN d_store_closed.d_date IS NOT NULL THEN 1 ELSE 0 END) AS store_closed_flag_sum,
    SUM(CASE WHEN d_cc_open.d_date IS NOT NULL THEN 1 ELSE 0 END) AS cc_open_flag_sum,
    SUM(CASE WHEN d_web_close.d_date IS NOT NULL THEN 1 ELSE 0 END) AS web_close_flag_sum
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_sales.d_year BETWEEN 2000 AND 2002
  AND s.s_state IS NOT NULL
  AND cc.cc_country = 'United States'
GROUP BY
    (d_sales.d_year * 100 + d_sales.d_month_seq),
    CASE WHEN s.s_state = 'CA' THEN 'California' ELSE s.s_state END,
    cc.cc_country,
    ws.web_country
HAVING COUNT(DISTINCT ss.ss_ticket_number) > 50
ORDER BY total_sales DESC
LIMIT 100
