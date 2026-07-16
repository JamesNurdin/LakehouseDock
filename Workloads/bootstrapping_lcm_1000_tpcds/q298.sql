SELECT
    cc.cc_company_name AS company_name,
    s.s_state AS store_state,
    cp.cp_type AS catalog_type,
    d_ret.d_year AS return_year,
    CASE WHEN cr.cr_return_amount > 500 THEN 'High' ELSE 'Low' END AS return_value_category,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(cr.cr_fee) AS total_fees,
    AVG(DATE_DIFF('day', d_cc_open.d_date, d_ret.d_date)) AS avg_days_since_cc_open,
    AVG(DATE_DIFF('day', d_cc_closed.d_date, d_ret.d_date)) AS avg_days_since_cc_closed,
    AVG(DATE_DIFF('day', d_cp_start.d_date, d_ret.d_date)) AS avg_days_since_page_start,
    AVG(DATE_DIFF('day', d_ret.d_date, d_cp_end.d_date)) AS avg_days_until_page_end
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_date BETWEEN d_cp_start.d_date AND d_cp_end.d_date
  AND d_ret.d_date >= d_cc_open.d_date
  AND d_ret.d_date <= d_cc_closed.d_date
GROUP BY
    cc.cc_company_name,
    s.s_state,
    cp.cp_type,
    d_ret.d_year,
    CASE WHEN cr.cr_return_amount > 500 THEN 'High' ELSE 'Low' END
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
