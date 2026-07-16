SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cr.cr_order_number) AS return_transactions,
    (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss)) AS net_contribution
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
    AND s.s_closed_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    sm.sm_type
ORDER BY net_contribution DESC
LIMIT 100
