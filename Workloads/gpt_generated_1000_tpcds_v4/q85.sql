WITH store_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_total,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
web_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_total,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_salutation,
    regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
    COALESCE(sa.store_return_total, 0) AS store_return_total,
    COALESCE(sa.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(wa.web_return_total, 0) AS web_return_total,
    COALESCE(wa.web_return_cnt, 0) AS web_return_cnt,
    (COALESCE(sa.store_return_total, 0) + COALESCE(wa.web_return_total, 0)) AS total_return_amount
FROM customer c
LEFT JOIN store_agg sa ON c.c_customer_sk = sa.customer_sk
LEFT JOIN web_agg wa ON c.c_customer_sk = wa.customer_sk
WHERE c.c_salutation LIKE 'M%'
  AND regexp_like(c.c_email_address, '^.+@.+\\.com$')
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
          AND wp.wp_autogen_flag = 'Y'
          AND wp.wp_url LIKE '%promo%'
    )
ORDER BY total_return_amount DESC
LIMIT 100
