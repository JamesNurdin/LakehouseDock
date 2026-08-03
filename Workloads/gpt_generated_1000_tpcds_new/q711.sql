SELECT c.c_salutation,
       sum(sr.sr_return_amt) AS total_return_amount,
       count(*) AS return_count
FROM tpcds.customer c
JOIN tpcds.store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_salutation = 'Ms.'
  AND sr.sr_return_tax > 100
  AND sr.sr_return_ship_cost < 100
GROUP BY c.c_salutation
