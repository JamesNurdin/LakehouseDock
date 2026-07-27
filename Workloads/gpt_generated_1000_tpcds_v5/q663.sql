SELECT
    c.c_customer_id,
    c.c_email_address,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_return_quantity) AS total_return_qty
FROM
    store_returns sr
JOIN
    customer c
    ON sr.sr_customer_sk = c.c_customer_sk
WHERE
    c.c_current_cdemo_sk = 929344
    AND sr.sr_return_amt > 1000
GROUP BY
    c.c_customer_id,
    c.c_email_address
ORDER BY
    total_return_amt DESC
LIMIT 100
