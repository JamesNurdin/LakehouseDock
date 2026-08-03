/* goal: Analyze customer distribution by state, counting distinct customers and distinct email domains while applying string‑based filters and household‑demographic criteria. */
WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_current_addr_sk,
        c.c_current_cdemo_sk,
        c.c_current_hdemo_sk,
        REGEXP_EXTRACT(c.c_email_address, '@([^\\.]+\\..+)$', 1) AS email_domain,
        SUBSTR(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_user
    FROM tpcds.customer c
    WHERE REGEXP_LIKE(c.c_email_address,
        '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
)
SELECT
    ca.ca_state,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    COUNT(DISTINCT fc.c_customer_sk) AS distinct_customers,
    COUNT(DISTINCT fc.email_domain) AS distinct_email_domains,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN hd.hd_buy_potential LIKE '%>10000%' THEN 1 ELSE 0 END) AS high_buy_potential_cnt
FROM filtered_customers fc
JOIN tpcds.customer_address ca
    ON fc.c_current_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
    ON fc.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON fc.c_current_hdemo_sk = hd.hd_demo_sk
-- LATERAL subquery referencing the preceding row
JOIN LATERAL (
    SELECT LENGTH(fc.email_user) AS email_user_len
) l ON TRUE
WHERE
    ca.ca_zip LIKE '9%'
    AND cd.cd_purchase_estimate > (
        SELECT MAX(cd2.cd_purchase_estimate)
        FROM tpcds.customer_demographics cd2
        WHERE cd2.cd_gender = 'M'
    )
    AND EXISTS (
        SELECT 1
        FROM tpcds.household_demographics hd2
        WHERE hd2.hd_income_band_sk = hd.hd_income_band_sk
          AND hd2.hd_vehicle_count > 1
    )
GROUP BY ca.ca_state, ca.ca_city
ORDER BY distinct_customers DESC, ca.ca_state
LIMIT 100
