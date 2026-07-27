WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain
    FROM customer c
    WHERE c.c_email_address LIKE '%@%.com'
      AND SUBSTRING(c.c_first_name, 1, 1) = 'A'
)
SELECT
    sm.sm_type,
    r.r_reason_desc,
    COUNT(DISTINCT fc.c_customer_sk) AS unique_refunded_customers,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    MIN(fc.full_name) AS example_customer_name,
    MIN(fc.email_domain) AS example_email_domain
FROM catalog_returns cr
JOIN filtered_customers fc
    ON cr.cr_refunded_customer_sk = fc.c_customer_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)damage|defect')
  AND cd.cd_education_status = 'College'
GROUP BY sm.sm_type, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
