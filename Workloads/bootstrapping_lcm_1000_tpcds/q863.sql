SELECT
    ca.ca_country,
    ca.ca_state,
    ca.ca_city,
    s.s_store_name,
    s.s_state AS store_state,
    s.s_city AS store_city,
    p.p_promo_name,
    p.p_discount_active,
    d.d_date AS event_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    COUNT(sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    CASE
        WHEN SUM(sr.sr_return_quantity) = 0 THEN NULL
        ELSE SUM(sr.sr_net_loss) / SUM(sr.sr_return_quantity)
    END AS net_loss_per_item
FROM date_dim d
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
   AND p.p_end_date_sk   = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_store_sk        = s.s_store_sk
JOIN customer_address ca
    ON ca.ca_address_sk = sr.sr_addr_sk
GROUP BY
    ca.ca_country,
    ca.ca_state,
    ca.ca_city,
    s.s_store_name,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
ORDER BY total_net_loss DESC
LIMIT 100
