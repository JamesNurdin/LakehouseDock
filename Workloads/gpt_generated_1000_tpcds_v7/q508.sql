SELECT
    d.d_year,
    p.p_promo_name,
    c.c_customer_id,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_ticket_count,
    MIN(d.d_date) AS first_return_date,
    MAX(d.d_date) AS last_return_date
FROM tpcds.store_returns sr
JOIN tpcds.date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN tpcds.customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN tpcds.promotion p
  ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND p.p_response_target = 1
  AND p.p_channel_radio = 'N'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY d.d_year, p.p_promo_name, c.c_customer_id
ORDER BY total_return_amount DESC
LIMIT 100
