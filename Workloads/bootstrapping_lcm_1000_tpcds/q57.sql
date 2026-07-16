SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    sm.sm_carrier,
    s.s_state,
    s.s_market_desc,
    p_start.p_promo_name AS promo_start_name,
    p_end.p_promo_name AS promo_end_name,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_inc_tax
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p_start ON p_start.p_start_date_sk = d.d_date_sk
JOIN promotion p_end ON p_end.p_end_date_sk = d.d_date_sk
WHERE d.d_year = 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    sm.sm_carrier,
    s.s_state,
    s.s_market_desc,
    p_start.p_promo_name,
    p_end.p_promo_name
ORDER BY total_net_loss DESC
LIMIT 100
