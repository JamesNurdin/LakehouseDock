WITH warranty_tickets AS (
    SELECT sr.sr_ticket_number
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)warranty')
      AND regexp_like(ca.ca_suite_number, '^Suite\\s+([1-9][0-9]{2,})')
),
gift_tickets AS (
    SELECT sr.sr_ticket_number
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)gift')
      AND ca.ca_suite_number LIKE 'Suite %'
),
target_tickets AS (
    SELECT sr_ticket_number FROM warranty_tickets
    EXCEPT
    SELECT sr_ticket_number FROM gift_tickets
)
SELECT d.d_year,
       r.r_reason_desc,
       MIN(regexp_extract(ca.ca_suite_number, '\\d+', 0)) AS suite_number,
       COUNT(*) AS return_cnt,
       SUM(sr.sr_return_amt) AS total_return_amount
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE sr.sr_ticket_number IN (SELECT sr_ticket_number FROM target_tickets)
GROUP BY d.d_year, r.r_reason_desc, ca.ca_suite_number
ORDER BY total_return_amount DESC
LIMIT 100
