WITH catalog_ret AS (
    SELECT
        c.c_customer_id,
        r.r_reason_desc,
        part AS email_part
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(split(c.c_email_address, '@')) AS t(part)
    WHERE cr.cr_return_amt_inc_tax > 100
      AND r.r_reason_desc LIKE '%price%'
),
web_ret AS (
    SELECT
        c.c_customer_id,
        r.r_reason_desc,
        part AS email_part
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(split(c.c_email_address, '@')) AS t(part)
    WHERE wr.wr_return_amt > 50
      AND r.r_reason_desc LIKE '%price%'
)
SELECT
    c_customer_id,
    r_reason_desc,
    email_part
FROM catalog_ret
INTERSECT
SELECT
    c_customer_id,
    r_reason_desc,
    email_part
FROM web_ret
ORDER BY c_customer_id
LIMIT 100
