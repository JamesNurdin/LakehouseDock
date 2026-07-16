SELECT
    dr.d_year AS return_year,
    dr.d_month_seq AS return_month_seq,
    CASE WHEN dr.d_month_seq BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_state,
    s.s_city,
    r.r_reason_desc,
    p.p_promo_name,
    p.p_channel_tv,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_fee) AS total_fee,
    SUM(p.p_cost) AS total_promotion_cost,
    SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN cr.cr_return_amount ELSE 0 END) AS damaged_return_amount,
    COUNT(*) FILTER (WHERE p.p_discount_active = 'Y') AS promo_discount_active_cnt,
    COUNT(*) FILTER (WHERE ds.d_year = dr.d_year AND ds.d_month_seq = dr.d_month_seq) AS same_month_store_closed_cnt
FROM catalog_returns cr
JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim ds ON s.s_closed_date_sk = ds.d_date_sk
JOIN promotion p ON p.p_start_date_sk = dr.d_date_sk
JOIN date_dim de ON p.p_end_date_sk = de.d_date_sk
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    CASE WHEN dr.d_month_seq BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END,
    s.s_state,
    s.s_city,
    r.r_reason_desc,
    p.p_promo_name,
    p.p_channel_tv
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
