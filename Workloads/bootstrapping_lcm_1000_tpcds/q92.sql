SELECT
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month,
    CONCAT(s.s_state, '-', cc.cc_state) AS region_pair,
    CASE
        WHEN SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS net_loss_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount_inc_tax,
    SUM(cr.cr_return_amt_inc_tax) AS total_catalog_return_amount_inc_tax,
    SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    MIN(d_cc_open.d_date) AS earliest_call_center_open_date,
    MAX(d_cc_closed.d_date) AS latest_call_center_closed_date
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    CONCAT(s.s_state, '-', cc.cc_state)
