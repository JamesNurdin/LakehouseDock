SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_date AS first_ship_date
FROM
    customer c
JOIN
    date_dim d
    ON c.c_first_shipto_date_sk = d.d_date_sk
WHERE
    c.c_salutation = 'Mrs.'
    AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
LIMIT 100
