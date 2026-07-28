SELECT
    sr.sr_ticket_number,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(ss.ss_net_paid) AS total_sales_paid
FROM tpcds.store_returns AS sr
JOIN tpcds.store_sales AS ss
  ON sr.sr_ticket_number = ss.ss_ticket_number
WHERE sr.sr_fee > 30.00
  AND ss.ss_coupon_amt < 5000.00
GROUP BY sr.sr_ticket_number
ORDER BY total_return_amount DESC
LIMIT 100
