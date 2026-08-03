SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
FROM tpcds.customer AS c
JOIN tpcds.store_returns AS sr
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_first_sales_date_sk = 2452162
  AND sr.sr_return_amt_inc_tax > 200
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_return_amount DESC
LIMIT 10
