SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    cp.cp_type AS catalog_page_type,
    CASE
        WHEN cp.cp_type = 'PROMO' THEN 'Promotion'
        WHEN cp.cp_type = 'STANDARD' THEN 'Standard'
        ELSE 'Other'
    END AS page_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    COUNT(cr.cr_order_number) AS total_orders,
    MIN(date_diff('day', d_cc_open.d_date, d_cc_closed.d_date)) AS call_center_open_days,
    AVG(date_diff('day', d_ret.d_date, d_store.d_date)) AS avg_days_return_to_store_close,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_net_loss), 0) AS return_to_loss_ratio
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_ret.d_year = 2020
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    cc.cc_name,
    s.s_store_name,
    cp.cp_type
ORDER BY total_net_loss DESC
LIMIT 100
