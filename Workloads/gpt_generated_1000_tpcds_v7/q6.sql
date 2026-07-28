SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_date
FROM
    tpcds.customer c
JOIN
    tpcds.date_dim d
      ON c.c_first_shipto_date_sk = d.d_date_sk
WHERE
    c.c_salutation = 'Ms.'
    AND d.d_quarter_name = '1993Q4'
ORDER BY
    d.d_date DESC
LIMIT 100
