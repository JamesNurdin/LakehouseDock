WITH filtered_customers AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       c.c_current_cdemo_sk,
       c.c_current_hdemo_sk,
       c.c_current_addr_sk,
       cd.cd_credit_rating,
       cd.cd_purchase_estimate,
       ca.ca_suite_number,
       ca.ca_city,
       ca.ca_state,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       regexp_extract(ca.ca_suite_number, '\\d+', 0) AS suite_num_str
   FROM
       tpcds.customer c
   JOIN tpcds.customer_demographics cd
       ON c.c_current_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.customer_address ca
       ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN tpcds.household_demographics hd
       ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE
       regexp_like(ca.ca_suite_number, '^Suite [0-9]+$')
       AND ca.ca_city LIKE '%County'
       AND EXISTS (
           SELECT 1
           FROM tpcds.customer c2
           WHERE c2.c_email_address LIKE '%@example.com'
                 AND c2.c_current_cdemo_sk = c.c_current_cdemo_sk
                 AND c2.c_customer_sk <> c.c_customer_sk
       )
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    CASE
        WHEN cd_credit_rating IN ('A', 'AA') THEN 'High'
        WHEN cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END AS credit_category,
    COUNT(*) AS customer_cnt,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CAST(suite_num_str AS integer)) AS total_suite_number
FROM
    filtered_customers
GROUP BY
    ib_lower_bound,
    ib_upper_bound,
    CASE
        WHEN cd_credit_rating IN ('A', 'AA') THEN 'High'
        WHEN cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY
    avg_purchase_estimate DESC
LIMIT 100
