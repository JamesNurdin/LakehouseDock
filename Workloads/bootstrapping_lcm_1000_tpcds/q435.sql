SELECT
    cc.cc_name,
    cc.cc_manager,
    s.s_store_name,
    s.s_city,
    d_cc_open.d_date AS call_center_open_date,
    d_cc_closed.d_date AS call_center_closed_date,
    d_store.d_date AS store_closed_date,
    d_cr.d_year AS catalog_return_year,
    d_wr.d_year AS web_return_year,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_combined_net_loss
FROM call_center cc
JOIN catalog_returns cr
    ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN date_dim d_wr
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE d_cr.d_year = 2001
  AND d_wr.d_year = 2001
GROUP BY
    cc.cc_name,
    cc.cc_manager,
    s.s_store_name,
    s.s_city,
    d_cc_open.d_date,
    d_cc_closed.d_date,
    d_store.d_date,
    d_cr.d_year,
    d_wr.d_year
ORDER BY total_combined_net_loss DESC
LIMIT 100
