SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    ca.ca_city AS customer_city,
    ca.ca_state AS customer_state,
    d_return.d_year AS return_year,
    d_return.d_moy AS return_month,
    p.p_promo_id,
    p.p_promo_name,
    d_return.d_date AS return_date,
    d_promo_end.d_date AS promo_end_date,
    d_closed.d_date AS store_closed_date,
    CASE
        WHEN d_closed.d_date IS NOT NULL AND d_closed.d_date < d_return.d_date THEN TRUE
        ELSE FALSE
    END AS store_closed_before_return,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(sr.sr_store_credit) AS total_store_credit,
    SUM(sr.sr_return_tax) AS total_return_tax,
    SUM(sr.sr_return_ship_cost) AS total_ship_cost
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_return.d_date <= d_promo_end.d_date
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca.ca_city,
    ca.ca_state,
    d_return.d_year,
    d_return.d_moy,
    p.p_promo_id,
    p.p_promo_name,
    d_return.d_date,
    d_promo_end.d_date,
    d_closed.d_date
ORDER BY total_return_amount DESC
LIMIT 100
