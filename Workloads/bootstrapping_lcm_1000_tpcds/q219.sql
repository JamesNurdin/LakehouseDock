SELECT
    d_ret.d_date AS return_date,
    d_ret.d_day_name AS return_day_name,
    d_ret.d_month_seq AS return_month_seq,
    d_closed.d_date AS store_closed_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    r.r_reason_desc,
    p.p_promo_name,
    p.p_cost,
    d_end.d_date AS promo_end_date,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(p.p_response_target) AS avg_response_target,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_ret.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND d_ret.d_date > d_closed.d_date
GROUP BY
    d_ret.d_date,
    d_ret.d_day_name,
    d_ret.d_month_seq,
    d_closed.d_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    r.r_reason_desc,
    p.p_promo_name,
    p.p_cost,
    d_end.d_date
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
