SELECT
    d.d_year,
    d.d_quarter_name,
    r.r_reason_desc,
    w.w_state,
    s.s_market_desc,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_quantity) AS total_quantity,
    MAX(cr.cr_return_amount) AS max_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    COUNT(DISTINCT s.s_store_id) AS stores_closed_on_return_date,
    (SELECT COUNT(*) FROM store s2 WHERE s2.s_state = w.w_state) AS total_stores_in_state,
    CASE
        WHEN w.w_gmt_offset < -5 THEN 'West'
        WHEN w.w_gmt_offset BETWEEN -5 AND -3 THEN 'Central'
        ELSE 'East'
    END AS region_category
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_quarter_name,
    r.r_reason_desc,
    w.w_state,
    s.s_market_desc,
    w.w_gmt_offset
HAVING SUM(cr.cr_net_loss) > 5000
ORDER BY total_net_loss DESC, d.d_year
LIMIT 100
