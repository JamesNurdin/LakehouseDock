SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_state,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    AVG(sr.sr_return_quantity) AS avg_quantity,
    MAX(sr.sr_return_amt) AS max_return_amt,
    COUNT(*) FILTER (WHERE sr.sr_return_quantity > 10) AS high_qty_returns,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
   AND p.p_end_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_state
HAVING SUM(sr.sr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
