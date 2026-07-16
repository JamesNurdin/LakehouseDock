SELECT
    s.s_store_id,
    s.s_state,
    dr.d_year,
    dr.d_month_seq,
    r.r_reason_desc,
    cp.cp_type,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_fee,
    AVG(date_diff('day', ds_start.d_date, ds_end.d_date)) AS avg_page_duration_days,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN SUM(cr.cr_net_loss) / SUM(cr.cr_return_amount) ELSE NULL END AS net_loss_ratio
FROM catalog_returns cr
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim ds_start
    ON cp.cp_start_date_sk = ds_start.d_date_sk
JOIN date_dim ds_end
    ON cp.cp_end_date_sk = ds_end.d_date_sk
WHERE dr.d_year BETWEEN 2000 AND 2020
GROUP BY
    s.s_store_id,
    s.s_state,
    dr.d_year,
    dr.d_month_seq,
    r.r_reason_desc,
    cp.cp_type
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
