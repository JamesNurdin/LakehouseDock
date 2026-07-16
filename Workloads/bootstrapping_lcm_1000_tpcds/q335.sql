SELECT
    cc.cc_state AS call_center_state,
    s.s_state AS store_state,
    dd_return.d_year AS return_year,
    CASE WHEN dd_return.d_moy <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    COUNT(*) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS positive_net_loss,
    SUM(CASE WHEN cr.cr_net_loss <= 0 THEN cr.cr_net_loss ELSE 0 END) AS non_positive_net_loss,
    MIN(dd_open.d_date) AS call_center_open_date,
    MAX(dd_closed.d_date) AS call_center_closed_date
FROM catalog_returns cr
JOIN date_dim dd_return
    ON cr.cr_returned_date_sk = dd_return.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dd_closed
    ON cc.cc_closed_date_sk = dd_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_closed.d_date_sk
JOIN date_dim dd_open
    ON cc.cc_open_date_sk = dd_open.d_date_sk
WHERE dd_return.d_year BETWEEN 2000 AND 2005
GROUP BY
    cc.cc_state,
    s.s_state,
    dd_return.d_year,
    CASE WHEN dd_return.d_moy <= 6 THEN 'H1' ELSE 'H2' END
ORDER BY total_net_loss DESC
LIMIT 100
