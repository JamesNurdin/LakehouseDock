SELECT
    s.s_store_id,
    s.s_store_name,
    d_return.d_year,
    d_return.d_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    r.r_reason_desc,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN promotion p
    ON d_return.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_return.d_year,
    d_return.d_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    r.r_reason_desc,
    d_start.d_date,
    d_end.d_date
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
