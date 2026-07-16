SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss)) AS net_margin,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    COUNT(DISTINCT cr.cr_order_number) AS return_transactions,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_cc_closed.d_date) AS call_center_close_date
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id
ORDER BY net_margin DESC
LIMIT 100
