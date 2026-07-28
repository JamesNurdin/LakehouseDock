SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  d.d_date
FROM tpcds.customer AS c
JOIN tpcds.date_dim AS d
  ON c.c_first_sales_date_sk = d.d_date_sk
WHERE c.c_salutation = 'Mr.'
  AND d.d_year = 2002
  AND d.d_holiday = 'N'
ORDER BY d.d_date DESC
