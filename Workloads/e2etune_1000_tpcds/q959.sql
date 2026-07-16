WITH demographic_metrics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_college_count) AS total_college_dependents,
        approx_percentile(cd.cd_purchase_estimate, 0.5) AS median_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_country IN ('SEYCHELLES', 'ETHIOPIA')
        AND cd.cd_credit_rating IN ('A', 'B')
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    HAVING
        COUNT(DISTINCT c.c_customer_sk) >= 10
)
SELECT
    dm.*, 
    ROW_NUMBER() OVER (ORDER BY dm.avg_purchase_estimate DESC) AS rank_by_avg_purchase
FROM
    demographic_metrics dm
ORDER BY
    dm.avg_purchase_estimate DESC
LIMIT 20
