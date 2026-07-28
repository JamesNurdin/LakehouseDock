WITH
    customer_returns AS (
        SELECT
            c.c_customer_sk,
            c.c_birth_year,
            c.c_email_address,
            SUM(sr.sr_return_amt) AS total_return_amt,
            SUM(sr.sr_fee) AS total_fee,
            COUNT(*) AS return_cnt
        FROM
            customer c
            INNER JOIN store_returns sr
                ON sr.sr_customer_sk = c.c_customer_sk
        WHERE
            c.c_birth_year BETWEEN 1960 AND 1990
            AND c.c_preferred_cust_flag = 'Y'
            AND sr.sr_return_amt > 100.00
            AND sr.sr_fee BETWEEN 30.00 AND 80.00
            AND sr.sr_return_ship_cost < 500.00
            AND sr.sr_refunded_cash <> 0
        GROUP BY
            c.c_customer_sk,
            c.c_birth_year,
            c.c_email_address
    ),
    qualified_web_customers AS (
        SELECT DISTINCT wp.wp_customer_sk AS c_customer_sk
        FROM web_page wp
        WHERE wp.wp_type = 'article'
            AND wp.wp_char_count > 4000
            AND wp.wp_rec_start_date >= DATE '2000-01-01'
        UNION ALL
        SELECT DISTINCT wp.wp_customer_sk AS c_customer_sk
        FROM web_page wp
        WHERE wp.wp_type = 'landing'
            AND wp.wp_image_count >= 5
            AND wp.wp_rec_end_date <= DATE '2025-12-31'
    )
SELECT
    cr.c_birth_year,
    COUNT(DISTINCT cr.c_customer_sk) AS num_customers,
    AVG(cr.total_return_amt) AS avg_return_amt,
    SUM(cr.total_fee) AS sum_fee
FROM
    customer_returns cr
WHERE
    EXISTS (
        SELECT 1 FROM qualified_web_customers qwc
        WHERE qwc.c_customer_sk = cr.c_customer_sk
    )
    AND cr.total_return_amt > 500.00
    AND cr.total_fee < 400.00
GROUP BY
    cr.c_birth_year
HAVING
    SUM(cr.total_fee) > 1000.00
ORDER BY
    avg_return_amt DESC
LIMIT 100
