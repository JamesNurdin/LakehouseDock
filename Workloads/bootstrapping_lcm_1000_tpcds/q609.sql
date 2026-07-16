SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    t.t_hour,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_combined_net_loss,
    COUNT(cr.cr_order_number) AS catalog_return_rows,
    COUNT(wr.wr_order_number) AS web_return_rows,
    AVG(cr.cr_fee) AS avg_catalog_fee,
    AVG(wr.wr_fee) AS avg_web_fee
FROM date_dim d
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    t.t_hour
HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0
ORDER BY total_combined_net_loss DESC
LIMIT 100
