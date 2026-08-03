WITH org_customers AS (
    SELECT c.c_customer_sk
    FROM tpcds.customer c
    WHERE regexp_like(c.c_email_address, '\\.org$')
),
us_customers AS (
    SELECT c.c_customer_sk
    FROM tpcds.customer c
    JOIN tpcds.customer_address a
        ON c.c_current_addr_sk = a.ca_address_sk
    WHERE a.ca_country = 'United States'
),
org_us_customers AS (
    SELECT c_customer_sk FROM org_customers
    INTERSECT
    SELECT c_customer_sk FROM us_customers
),
high_risk_customers AS (
    SELECT c.c_customer_sk
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics d
        ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE d.cd_credit_rating = 'High Risk'
),
eligible_customers AS (
    SELECT c_customer_sk FROM org_us_customers
    EXCEPT
    SELECT c_customer_sk FROM high_risk_customers
)
SELECT
    d.cd_credit_rating,
    d.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(d.cd_purchase_estimate) AS total_estimate,
    SUM(CASE WHEN d.cd_credit_rating = 'Good' THEN d.cd_purchase_estimate ELSE 0 END) AS good_credit_estimate,
    CASE
        WHEN d.cd_credit_rating = 'Good' THEN 'Preferred'
        ELSE 'Standard'
    END AS customer_segment,
    array_agg(DISTINCT regexp_extract(c.c_email_address, '@([^.]*)\\.', 1)) AS email_domains
FROM tpcds.customer c
JOIN tpcds.customer_demographics d
    ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN tpcds.customer_address a
    ON c.c_current_addr_sk = a.ca_address_sk
JOIN eligible_customers e
    ON c.c_customer_sk = e.c_customer_sk
WHERE a.ca_country = 'United States'
  AND c.c_email_address LIKE '%@%.org%'
GROUP BY ROLLUP(d.cd_credit_rating, d.cd_gender)
ORDER BY d.cd_credit_rating, d.cd_gender
