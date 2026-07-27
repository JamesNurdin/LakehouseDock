WITH filtered_customers AS (
    SELECT
        cu.c_customer_id,
        cu.c_first_name,
        cu.c_last_name,
        cu.c_preferred_cust_flag,
        cu.c_email_address,
        ca.ca_state AS state,
        ca.ca_city,
        cd.cd_purchase_estimate,
        regexp_extract(cu.c_email_address, '@(.+)$', 1) AS email_domain
    FROM tpcds.customer cu
    JOIN tpcds.customer_address ca
        ON cu.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cu.c_preferred_cust_flag = 'Y'
      AND regexp_like(ca.ca_street_name, '\\d{1,}th')
      AND ca.ca_city LIKE 'S%'
)
SELECT
    state,
    email_domain,
    COUNT(*) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM filtered_customers
GROUP BY state, email_domain
ORDER BY customer_count DESC, state
LIMIT 100
