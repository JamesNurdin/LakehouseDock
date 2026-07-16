SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    c.cc_name AS call_center_name,
    c.cc_city AS call_center_city,
    p.p_promo_name,
    dr_return.d_year,
    dr_return.d_quarter_name,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_tax) AS total_return_tax,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost
FROM store_returns sr
JOIN date_dim dr_return
    ON sr.sr_returned_date_sk = dr_return.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr_store_closed
    ON s.s_closed_date_sk = dr_store_closed.d_date_sk
JOIN call_center c
    ON c.cc_closed_date_sk = dr_store_closed.d_date_sk
JOIN date_dim dr_cc_open
    ON c.cc_open_date_sk = dr_cc_open.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = dr_cc_open.d_date_sk
JOIN date_dim dr_promo_end
    ON p.p_end_date_sk = dr_promo_end.d_date_sk
WHERE dr_return.d_date_sk BETWEEN dr_cc_open.d_date_sk AND dr_promo_end.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    c.cc_name,
    c.cc_city,
    p.p_promo_name,
    dr_return.d_year,
    dr_return.d_quarter_name
ORDER BY total_net_loss DESC
LIMIT 100
