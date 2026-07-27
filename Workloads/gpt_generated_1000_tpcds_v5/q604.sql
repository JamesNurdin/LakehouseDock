WITH filtered_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain
    FROM
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        regexp_like(c.c_email_address, '^.*@example\\.(com|org)$')
        AND ca.ca_zip LIKE '8%'
        AND cd.cd_purchase_estimate > 1000
)
SELECT
    fc.ca_state,
    fc.email_domain,
    COUNT(DISTINCT fc.c_customer_id) AS num_customers,
    AVG(fc.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN fc.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers
FROM
    filtered_customers fc
WHERE
    EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_gender = fc.cd_gender
          AND cd2.cd_purchase_estimate > 5000
    )
GROUP BY
    fc.ca_state,
    fc.email_domain
ORDER BY
    num_customers DESC,
    avg_purchase_estimate DESC
LIMIT 100
