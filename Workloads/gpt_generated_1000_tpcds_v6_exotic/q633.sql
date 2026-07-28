WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_addr_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
)
SELECT
    r.r_reason_desc,
    cd.cd_gender,
    COUNT(*) AS num_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    REGEXP_EXTRACT(ca.ca_suite_number, '(\\d+)', 1) AS suite_number_digits,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    CASE
        WHEN REGEXP_LIKE(ca.ca_street_name, '^Pine|Oak') THEN 'PineOrOakStreet'
        ELSE 'OtherStreet'
    END AS street_category
FROM filtered_returns fr
JOIN customer_demographics cd
    ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON fr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
WHERE
    REGEXP_LIKE(ca.ca_suite_number, 'Suite [12][0-9][0-9]')
    AND ca.ca_city LIKE 'A%'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_cdemo_sk = cd.cd_demo_sk
          AND cr2.cr_return_amount > 500
        LIMIT 1
    )
GROUP BY
    r.r_reason_desc,
    cd.cd_gender,
    ca.ca_suite_number,
    ca.ca_city,
    ca.ca_state,
    ca.ca_street_name
ORDER BY total_return_amount DESC
LIMIT 100
