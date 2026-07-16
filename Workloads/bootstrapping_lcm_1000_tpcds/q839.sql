SELECT
    d_cc.d_year AS cc_closed_year,
    d_cc.d_month_seq AS cc_closed_month,
    d_open.d_year AS cc_open_year,
    d_open.d_month_seq AS cc_open_month,
    cc.cc_division,
    cc.cc_market_manager,
    d_cr.d_year AS return_year,
    d_cr.d_month_seq AS return_month,
    s.s_division_id,
    s.s_market_manager,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    (SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt)) AS combined_return_amount,
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) AS combined_net_loss,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct
FROM call_center cc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_cr.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE cc.cc_state = s.s_state
GROUP BY
    d_cc.d_year,
    d_cc.d_month_seq,
    d_open.d_year,
    d_open.d_month_seq,
    cc.cc_division,
    cc.cc_market_manager,
    d_cr.d_year,
    d_cr.d_month_seq,
    s.s_division_id,
    s.s_market_manager
ORDER BY d_cc.d_year DESC, d_cr.d_year DESC
LIMIT 100
