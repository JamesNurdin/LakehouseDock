WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_email_address,
        c_first_name,
        c_last_name,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        CASE
            WHEN regexp_like(c_email_address, '@gmail\\.com$') THEN 'GMAIL'
            WHEN regexp_like(c_email_address, '@yahoo\\.com$') THEN 'YAHOO'
            ELSE 'OTHER'
        END AS email_provider,
        CASE
            WHEN c_preferred_cust_flag = 'Y' THEN 1
            ELSE 0
        END AS is_preferred
    FROM customer
    WHERE c_email_address LIKE '%@%.%'
      AND regexp_extract(c_email_address, '@([^\\.]+)\\.', 1) IS NOT NULL
)
SELECT
    fc.email_provider,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN fc.is_preferred = 1 THEN cr.cr_net_loss ELSE 0 END) AS preferred_net_loss
FROM catalog_returns cr
JOIN filtered_customers fc
    ON cr.cr_refunded_customer_sk = fc.c_customer_sk
WHERE cr.cr_return_amount > 50
  AND cr.cr_return_quantity BETWEEN 1 AND 100
GROUP BY fc.email_provider
ORDER BY total_net_loss DESC
LIMIT 100
