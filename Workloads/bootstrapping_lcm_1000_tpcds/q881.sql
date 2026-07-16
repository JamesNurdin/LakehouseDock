SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    s.s_store_id,
    s.s_city AS store_city,
    s.s_state AS store_state,
    dcr.d_year AS year,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_return_tax) AS total_catalog_return_tax,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets
FROM call_center cc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dcr
    ON cr.cr_returned_date_sk = dcr.d_date_sk
JOIN date_dim dcc_closed
    ON cc.cc_closed_date_sk = dcc_closed.d_date_sk
JOIN date_dim dcc_open
    ON cc.cc_open_date_sk = dcc_open.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = dcr.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN date_dim dstore_closed
    ON s.s_closed_date_sk = dstore_closed.d_date_sk
WHERE dcr.d_year = 2022
  AND cc.cc_state = 'TX'
  AND s.s_state = 'TX'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    s.s_store_id,
    s.s_city,
    s.s_state,
    dcr.d_year
ORDER BY total_catalog_return_amount DESC
LIMIT 100
