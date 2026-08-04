WITH cust_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        regexp_extract(c.c_email_address, '@([A-Za-z0-9]+)\\.', 1) AS email_domain,
        split(c.c_last_name, '') AS last_name_chars,
        c.c_salutation
    FROM customer c
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.(com|org)$')
      AND c.c_salutation LIKE 'M%'
)

SELECT
    cd.c_customer_sk,
    cd.full_name,
    cd.email_domain,
    d.d_year,
    d.d_quarter_name,
    chr AS last_name_char,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amt,
    CASE
        WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_category,
    (SELECT AVG(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_returning_customer_sk = cd.c_customer_sk) AS avg_return_amt_for_customer,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_returns wr3
            WHERE wr3.wr_returning_customer_sk = cd.c_customer_sk
              AND wr3.wr_return_amt > 500
        ) THEN 1
        ELSE 0
    END AS has_large_return
FROM cust_data cd
JOIN web_returns wr
  ON wr.wr_returning_customer_sk = cd.c_customer_sk
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
CROSS JOIN UNNEST(cd.last_name_chars) AS t(chr)
WHERE d.d_year = 2001
GROUP BY
    cd.c_customer_sk,
    cd.full_name,
    cd.email_domain,
    d.d_year,
    d.d_quarter_name,
    chr
HAVING COUNT(*) > 1
ORDER BY total_return_amt DESC
LIMIT 100
