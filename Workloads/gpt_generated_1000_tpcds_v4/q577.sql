WITH customer_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_fee) AS avg_fee,
        ROW_NUMBER() OVER (PARTITION BY c.c_birth_country ORDER BY SUM(sr.sr_return_amt) DESC) AS rn_country
    FROM
        store_returns sr
        JOIN customer c
            ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_country IN ('SURINAME', 'TURKMENISTAN', 'NIUE', 'TOGO')
        AND c.c_preferred_cust_flag = 'Y'
        AND c.c_first_name LIKE 'A%'
        AND sr.sr_fee > 20
        AND sr.sr_store_credit < 300
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country
)
SELECT DISTINCT
    cr.c_birth_country,
    AVG(cr.total_return_amt) AS avg_total_return,
    COUNT(DISTINCT cr.c_customer_sk) AS distinct_customers
FROM
    customer_returns cr
WHERE
    cr.return_cnt > 2
    AND cr.rn_country = 1
GROUP BY
    cr.c_birth_country
HAVING
    AVG(cr.total_return_amt) > 100
ORDER BY
    avg_total_return DESC
LIMIT 100
