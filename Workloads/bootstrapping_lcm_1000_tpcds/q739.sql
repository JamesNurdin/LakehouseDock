SELECT
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    (d_ret.d_year * 100 + d_ret.d_month_seq) AS year_month,
    r.r_reason_desc,
    CASE WHEN cr.cr_return_quantity >= 10 THEN 'High Qty' ELSE 'Low Qty' END AS qty_category,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    COUNT(DISTINCT r.r_reason_id) AS distinct_reason_cnt,
    MIN(d_start.d_date) AS page_start_date,
    MAX(d_end.d_date)   AS page_end_date,
    MIN(s.s_rec_start_date) AS store_open_date,
    MAX(s.s_rec_end_date)   AS store_close_date
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    (d_ret.d_year * 100 + d_ret.d_month_seq),
    r.r_reason_desc,
    CASE WHEN cr.cr_return_quantity >= 10 THEN 'High Qty' ELSE 'Low Qty' END
HAVING COUNT(*) > 0
ORDER BY total_return_amount DESC
LIMIT 100
