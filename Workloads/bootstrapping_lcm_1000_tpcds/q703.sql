SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    s.s_store_id,
    s.s_state,
    r.r_reason_desc,
    p.p_promo_id,
    p.p_promo_name,
    COUNT(*) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_count
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN promotion p
    ON sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_closed.d_date_sk IS NULL OR d_closed.d_date_sk > sr.sr_returned_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_state,
    r.r_reason_desc,
    p.p_promo_id,
    p.p_promo_name
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
