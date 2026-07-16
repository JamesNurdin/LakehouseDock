SELECT
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    sm.sm_type,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    COUNT(cr.cr_order_number) AS num_returns,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(d_sales.d_date) AS latest_sales_date,
    MIN(d_closed.d_date) AS store_closed_date
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d_sales.d_year = 2020
  AND s.s_state = 'CA'
GROUP BY s.s_store_name, d_sales.d_year, d_sales.d_month_seq, sm.sm_type
ORDER BY total_sales DESC
LIMIT 100
