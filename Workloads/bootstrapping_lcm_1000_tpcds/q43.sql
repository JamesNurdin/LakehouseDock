SELECT
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    COALESCE(SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END), 0) AS total_active_promo_cost,
    MAX(d_ret.d_date) AS last_return_date,
    MIN(d_ret.d_date) AS first_return_date,
    CASE WHEN d_closed.d_date IS NOT NULL THEN 'Closed' ELSE 'Open' END AS store_status_at_return
FROM date_dim d_ret
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
       OR p.p_end_date_sk = d_ret.d_date_sk
WHERE s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_closed.d_date
HAVING SUM(sr.sr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 100
