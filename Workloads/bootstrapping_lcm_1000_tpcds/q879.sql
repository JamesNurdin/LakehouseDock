SELECT
    cc.cc_division,
    cc.cc_market_manager,
    s.s_state,
    sm.sm_type,
    d_ret.d_year,
    d_ret.d_quarter_name,
    d_cc.d_month_seq AS cc_closed_month_seq,
    d_open.d_month_seq AS cc_open_month_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN cr.cr_return_tax > 0 THEN cr.cr_return_tax ELSE 0 END) AS total_return_tax,
    SUM(CASE WHEN sm.sm_carrier = 'UPS' THEN cr.cr_return_amount ELSE 0 END) AS ups_return_amount,
    SUM(CASE WHEN s.s_gmt_offset > 0 THEN cr.cr_return_amount ELSE 0 END) AS east_coast_return_amount
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
GROUP BY
    cc.cc_division,
    cc.cc_market_manager,
    s.s_state,
    sm.sm_type,
    d_ret.d_year,
    d_ret.d_quarter_name,
    d_cc.d_month_seq,
    d_open.d_month_seq
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
