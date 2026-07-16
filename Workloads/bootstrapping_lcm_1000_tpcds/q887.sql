SELECT
    s.s_store_id,
    s.s_city,
    w.w_warehouse_name,
    cp.cp_type,
    d_ret.d_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_fee) AS total_fees,
    SUM(cr.cr_return_quantity) AS total_quantity,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_net_loss) / NULLIF(COUNT(*), 0) AS avg_net_loss_per_return,
    DATE_DIFF('day', d_page_start.d_date, d_page_end.d_date) AS catalog_page_duration_days,
    CASE WHEN SUM(cr.cr_net_loss) > 50000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year >= 2000
GROUP BY
    s.s_store_id,
    s.s_city,
    w.w_warehouse_name,
    cp.cp_type,
    d_ret.d_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    d_page_start.d_date,
    d_page_end.d_date
ORDER BY total_net_loss DESC
LIMIT 100
