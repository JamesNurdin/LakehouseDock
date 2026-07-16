SELECT
    s.s_store_id,
    s.s_store_name,
    p.p_promo_id,
    p.p_promo_name,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date,
    d_return.d_year AS return_year,
    ca.ca_state AS customer_state,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_discount_active = 'Y'
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_return.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
  AND (d_closed.d_date IS NULL OR d_closed.d_date > d_return.d_date)
GROUP BY
    s.s_store_id,
    s.s_store_name,
    p.p_promo_id,
    p.p_promo_name,
    d_return.d_year,
    ca.ca_state
