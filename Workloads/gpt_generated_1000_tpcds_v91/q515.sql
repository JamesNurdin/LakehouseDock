SELECT
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM store_returns sr
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_reversed_charge > 500
  AND sr.sr_fee < 50
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
