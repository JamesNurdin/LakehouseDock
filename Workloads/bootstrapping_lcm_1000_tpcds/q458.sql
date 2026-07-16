SELECT
    d_ret.d_date AS return_date,
    d_ret.d_day_name AS day_name,
    t.t_hour,
    t.t_minute,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    p.p_promo_id,
    p.p_promo_name,
    d_end.d_date AS promo_end_date,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_transactions
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
GROUP BY
    d_ret.d_date,
    d_ret.d_day_name,
    t.t_hour,
    t.t_minute,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    p.p_promo_id,
    p.p_promo_name,
    d_end.d_date
ORDER BY total_return_amount DESC
LIMIT 100
