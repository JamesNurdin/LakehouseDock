SELECT
    cp.cp_department,
    cp.cp_type,
    d_ret.d_year,
    d_ret.d_month_seq,
    w.w_state,
    w.w_city,
    s.s_state,
    s.s_city,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    CASE
        WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS return_volume_category
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
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
    d_ret.d_year,
    d_ret.d_month_seq,
    w.w_state,
    w.w_city,
    s.s_state,
    s.s_city
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
