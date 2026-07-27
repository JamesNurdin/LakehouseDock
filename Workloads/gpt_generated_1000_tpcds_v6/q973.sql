WITH demo_agg AS (
    SELECT
        cd_demo_sk,
        AVG(cd_purchase_estimate) AS avg_purchase_est,
        MAX(cd_dep_count) AS max_dep_cnt
    FROM customer_demographics
    GROUP BY cd_demo_sk
)
SELECT
    ca.ca_city,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS customer_cnt,
    SUM(cd.cd_purchase_estimate) AS total_purchase_est,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_est,
    MIN(cd.cd_dep_count) AS min_dep_cnt,
    MAX(demo_agg.max_dep_cnt) AS max_dep_cnt_over_demo
FROM customer c
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN demo_agg
    ON cd.cd_demo_sk = demo_agg.cd_demo_sk
WHERE ca.ca_city IN ('Fairview', 'Valley View')
  AND ca.ca_state = 'CA'
  AND c.c_birth_month = 5
  AND c.c_birth_year BETWEEN 1960 AND 1970
  AND cd.cd_credit_rating = 'Excellent'
  AND cd.cd_dep_college_count >= 1
  AND c.c_preferred_cust_flag = 'Y'
  AND EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_zip LIKE '9%'
          AND ca2.ca_address_sk = c.c_current_addr_sk
      )
GROUP BY ca.ca_city, cd.cd_gender
ORDER BY total_purchase_est DESC
LIMIT 100
