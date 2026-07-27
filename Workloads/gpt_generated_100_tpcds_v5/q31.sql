/*
  Goal: Analyze store return performance by year, state and city, focusing on high‑value net losses and applying realistic filters on store, date, employee count and promotion activity.
*/
WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        d.d_year,
        s.s_state,
        s.s_city,
        s.s_number_employees,
        p.p_discount_active
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    WHERE s.s_city = 'Liberty'
      AND d.d_year = 1914
      AND s.s_number_employees BETWEEN 200 AND 300
      AND p.p_discount_active = 'Y'
)
SELECT
    d_year,
    s_state,
    s_city,
    COUNT(DISTINCT sr_ticket_number) AS return_count,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN sr_net_loss > 1000 THEN sr_net_loss ELSE 0 END) AS high_net_loss,
    MIN(sr_return_quantity) AS min_quantity,
    MAX(sr_return_quantity) AS max_quantity
FROM base
GROUP BY d_year, s_state, s_city
ORDER BY total_return_amount DESC
LIMIT 100
