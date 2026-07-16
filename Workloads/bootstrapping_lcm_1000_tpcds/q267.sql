SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    r.r_reason_desc,
    p.p_promo_name,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    d_closed.d_date AS store_closed_date,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(CASE WHEN sr.sr_return_quantity > 1 THEN sr.sr_return_quantity ELSE 0 END) AS total_return_quantity_over_one
FROM store_returns sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN promotion p
  ON d_ret.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
LEFT JOIN date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_ret.d_year >= 2020
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    r.r_reason_desc,
    p.p_promo_name,
    d_start.d_date,
    d_end.d_date,
    d_closed.d_date
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
