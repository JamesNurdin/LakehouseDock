SELECT
    cp.cp_department,
    s.s_state,
    ws.web_state,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    AVG(date_diff('day', d_start.d_date, d_ret.d_date)) AS avg_days_start_to_return,
    MAX(date_diff('day', d_ret.d_date, d_end.d_date)) AS max_days_to_end
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
WHERE d_ret.d_date BETWEEN d_start.d_date AND d_end.d_date
GROUP BY cp.cp_department, s.s_state, ws.web_state, d_ret.d_year, d_ret.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
