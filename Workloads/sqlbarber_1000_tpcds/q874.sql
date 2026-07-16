SELECT
    c.c_customer_id,
    ca.ca_state,
    d.d_year,
    SUM(cd.cd_purchase_estimate) AS total_estimate,
    COUNT(*) AS cust_count
FROM customer c
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d
    ON c.c_first_shipto_date_sk = d.d_date_sk
WHERE cd.cd_gender = 'M'
  AND d.d_year = 1913
  AND c.c_customer_id IN (
        SELECT c2.c_customer_id
        FROM customer c2
        WHERE c2.c_preferred_cust_flag = 'N'
    )
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    d.d_year
HAVING COUNT(*) > 0
