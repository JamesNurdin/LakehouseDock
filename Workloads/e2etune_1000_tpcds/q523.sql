SELECT
    p.p_promo_name,
    cp.cp_type,
    d.d_year,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(sr.sr_fee) AS total_fee,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash
FROM store_returns sr
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cd.cd_gender = 'M'
  AND cp.cp_type = 'monthly'
  AND p.p_discount_active = 'Y'
  AND d.d_date_sk <= p.p_end_date_sk
  AND d.d_date_sk <= cp.cp_end_date_sk
GROUP BY p.p_promo_name, cp.cp_type, d.d_year
HAVING SUM(sr.sr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 50
