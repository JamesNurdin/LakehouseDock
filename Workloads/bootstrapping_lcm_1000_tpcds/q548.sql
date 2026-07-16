SELECT
    d.d_year,
    sm.sm_type,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    AVG(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount END) AS avg_large_catalog_return_amt,
    AVG(CASE WHEN wr.wr_return_quantity > 5 THEN wr.wr_return_amt END) AS avg_large_web_return_amt
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY d.d_year, sm.sm_type, s.s_state
HAVING (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 0
ORDER BY total_net_loss DESC
LIMIT 100
