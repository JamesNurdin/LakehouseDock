WITH addr_filtered AS (
    SELECT
        ca_address_sk,
        ca_state,
        ca_city,
        ca_street_name,
        regexp_extract(ca_street_name, '(\\d+)', 1) AS street_num_extracted
    FROM customer_address
    WHERE regexp_like(ca_street_name, '\\d{2,}')
      AND ca_city LIKE 'A%'
)
SELECT
    p.p_promo_name,
    CONCAT(a.ca_state, '-', a.ca_city) AS state_city,
    a.street_num_extracted,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_store_credit) AS avg_store_credit
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN addr_filtered a ON sr.sr_addr_sk = a.ca_address_sk
JOIN promotion p ON 1 = 1
JOIN date_dim sd ON p.p_start_date_sk = sd.d_date_sk
JOIN date_dim ed ON p.p_end_date_sk = ed.d_date_sk
WHERE d.d_date BETWEEN sd.d_date AND ed.d_date
  AND d.d_year = 2001
  AND (p.p_channel_email = 'Y' OR p.p_channel_dmail = 'Y')
GROUP BY
    p.p_promo_name,
    CONCAT(a.ca_state, '-', a.ca_city),
    a.street_num_extracted
ORDER BY total_net_loss DESC
LIMIT 100
