WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_suite_number,
        REGEXP_EXTRACT(ca.ca_suite_number, '\\d+', 1) AS suite_number_extracted,
        CASE
            WHEN REGEXP_LIKE(ca.ca_suite_number, '^Suite [A-Z]') THEN 'Alpha'
            ELSE 'Numeric'
        END AS suite_category
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_country = 'United States'
        AND ca.ca_suite_number LIKE 'Suite %'
        AND REGEXP_LIKE(ca.ca_suite_number, '[0-9]+')
)
SELECT
    cd_education_status,
    suite_category,
    CONCAT(ca_city, ', ', ca_state) AS location,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_net_loss) AS avg_net_loss,
    COUNT(*) AS returns_cnt
FROM filtered_returns
GROUP BY
    cd_education_status,
    suite_category,
    CONCAT(ca_city, ', ', ca_state)
ORDER BY total_return_amount DESC
LIMIT 20
