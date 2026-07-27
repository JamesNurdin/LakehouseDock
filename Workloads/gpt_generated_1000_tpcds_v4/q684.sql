WITH filtered AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        cd.cd_credit_rating,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        ca.ca_city,
        ca.ca_gmt_offset,
        CASE
            WHEN cd.cd_purchase_estimate >= 8000 THEN 'High'
            WHEN cd.cd_purchase_estimate >= 5000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_tier
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
      AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
      AND cd.cd_credit_rating IN ('Good', 'High Risk')
      AND cd.cd_education_status IN ('College', '4 yr Degree')
      AND c.c_birth_month BETWEEN 1 AND 6
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    DISTINCT f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.ca_state,
    f.cd_credit_rating,
    f.purchase_tier,
    f.cd_purchase_estimate,
    RANK() OVER (PARTITION BY f.ca_state ORDER BY f.cd_purchase_estimate DESC) AS state_purchase_rank,
    AVG(f.cd_purchase_estimate) OVER (PARTITION BY f.ca_state) AS avg_state_purchase,
    ROW_NUMBER() OVER (ORDER BY f.cd_purchase_estimate DESC) AS global_purchase_rownum
FROM filtered f
ORDER BY f.ca_state, state_purchase_rank
LIMIT 100
