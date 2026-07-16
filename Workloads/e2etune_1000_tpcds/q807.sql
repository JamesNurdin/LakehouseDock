WITH cust_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(cd.cd_purchase_estimate) AS total_est,
        AVG(cd.cd_purchase_estimate) AS avg_est,
        COUNT(*) AS cust_cnt
    FROM customer_demographics cd
    WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT
    w.w_state,
    d.d_year,
    ca.cd_gender,
    ca.cd_marital_status,
    ca.cd_credit_rating,
    ca.cust_cnt,
    ca.total_est,
    ca.avg_est,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY ca.cust_cnt DESC) AS rank_in_state
FROM warehouse w
CROSS JOIN date_dim d
CROSS JOIN cust_agg ca
WHERE d.d_year BETWEEN 1995 AND 2005
  AND w.w_country = 'United States'
ORDER BY w.w_state, rank_in_state
LIMIT 200
