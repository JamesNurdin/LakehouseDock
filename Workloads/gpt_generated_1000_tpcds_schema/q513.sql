SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sr.sr_return_amt_inc_tax,
    sr.sr_return_tax
FROM store_returns sr
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE sr.sr_return_ship_cost BETWEEN 100.00 AND 300.00
  AND c.c_first_sales_date_sk = 2452162
