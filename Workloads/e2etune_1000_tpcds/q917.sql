WITH agg AS (
    SELECT
        ib.ib_income_band_sk AS income_band_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd.cd_education_status AS education_status,
        COUNT(DISTINCT cd.cd_demo_sk) AS num_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_dep_employed_count) AS avg_dep_employed
    FROM
        customer_demographics cd
    JOIN
        income_band ib
        ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE
        cd.cd_marital_status = 'M'
        AND cd.cd_dep_count > 0
        AND cd.cd_education_status IN ('College', '4 yr Degree')
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd.cd_education_status
    HAVING
        SUM(cd.cd_purchase_estimate) > 5000
)
SELECT
    income_band_id,
    ib_lower_bound,
    ib_upper_bound,
    education_status,
    num_customers,
    total_purchase_estimate,
    avg_dep_employed,
    RANK() OVER (ORDER BY total_purchase_estimate DESC) AS purchase_rank
FROM agg
ORDER BY total_purchase_estimate DESC
LIMIT 20
