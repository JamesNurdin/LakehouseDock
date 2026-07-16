SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS return_half_year,
    cc.cc_division_name AS call_center_division,
    s.s_division_name AS store_division,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_return_amount_per_quantity,
    AVG(date_diff('day', d_cc_open.d_date, d_store.d_date)) AS avg_cc_to_store_close_lifespan_days,
    d_store.d_year AS store_closed_year,
    d_store.d_month_seq AS store_closed_month,
    CASE WHEN SUM(cr.cr_return_amount) > 100000 THEN 'HIGH' ELSE 'LOW' END AS return_category
FROM store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    cc.cc_division_name,
    s.s_division_name,
    d_store.d_year,
    d_store.d_month_seq
