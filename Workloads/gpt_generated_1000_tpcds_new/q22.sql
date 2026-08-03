SELECT
    c.c_customer_id,
    c.c_last_name,
    SUM(wr.wr_return_amt) AS total_return_amount
FROM
    web_returns wr
JOIN
    customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE
    wr.wr_item_sk = 107054
    AND c.c_birth_month = 11
GROUP BY
    c.c_customer_id,
    c.c_last_name
ORDER BY
    total_return_amount DESC
LIMIT 10
