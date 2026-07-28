WITH avg_return AS (
    SELECT AVG(cr_return_amt_inc_tax) AS avg_inc_tax
    FROM tpcds.catalog_returns
),
filtered AS (
    SELECT
        cr.cr_refunded_customer_sk,
        cr.cr_net_loss,
        cr.cr_return_amt_inc_tax,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS domain,
        substr(c.c_email_address, 1, position('@' IN c.c_email_address) - 1) AS user_part
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z]+\\.[A-Za-z]+@.*\\.com$')
      AND c.c_email_address LIKE '%@%org%'
      AND cr.cr_return_amt_inc_tax > (SELECT avg_inc_tax FROM avg_return)
)
SELECT
    domain,
    COUNT(DISTINCT cr_refunded_customer_sk) AS distinct_customers,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amt_inc_tax) AS avg_return_inc_tax,
    MAX(user_part) AS example_user_part
FROM filtered
GROUP BY domain
ORDER BY total_net_loss DESC
LIMIT 5
