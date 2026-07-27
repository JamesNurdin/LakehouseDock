WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        CASE
            WHEN regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$') THEN 'example.com'
            ELSE 'other'
        END AS email_domain_flag,
        regexp_extract(c.c_email_address, '(@[^@]+)$', 1) AS email_domain
    FROM tpcds.customer c
    WHERE regexp_like(c.c_email_address, '[0-9]{2,}')
),
catalog_refunds AS (
    SELECT
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cash,
        cr.cr_call_center_sk,
        cr.cr_return_amount
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_refunded_cash > 0
)
SELECT
    cc.cc_name,
    fc.email_domain_flag,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(CASE WHEN cr.cr_refunded_cash > 100 THEN cr.cr_refunded_cash ELSE 0 END) AS high_refund_cash,
    CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
    SUBSTRING(wp.wp_url, 1, 10) AS url_prefix,
    fc.email_domain
FROM catalog_refunds cr
JOIN filtered_customers fc ON cr.cr_refunded_customer_sk = fc.c_customer_sk
JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.web_page wp ON fc.c_customer_sk = wp.wp_customer_sk
WHERE wp.wp_url LIKE 'http://%shop%'
  AND regexp_like(wp.wp_type, '^(home|category)$')
GROUP BY
    cc.cc_name,
    fc.email_domain_flag,
    fc.c_first_name,
    fc.c_last_name,
    wp.wp_url,
    fc.email_domain
ORDER BY total_refunded_cash DESC
LIMIT 100
