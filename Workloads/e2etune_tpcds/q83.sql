WITH demo_stats AS (
    SELECT
        cd.cd_education_status,
        cd.cd_credit_rating,
        COUNT(*) AS cust_cnt,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_employed_count) AS total_employed_dependents,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_cnt,
        SUM(CASE WHEN cd.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_cnt
    FROM
        customer_demographics cd
    WHERE
        cd.cd_purchase_estimate >= 1000
        AND cd.cd_credit_rating IN ('Good', 'Low Risk')
    GROUP BY
        cd.cd_education_status,
        cd.cd_credit_rating
    HAVING
        COUNT(*) > 5
)
SELECT
    ds.cd_education_status,
    ds.cd_credit_rating,
    ds.cust_cnt,
    ds.avg_purchase_estimate,
    ds.total_employed_dependents,
    ds.married_cnt,
    ds.single_cnt,
    r.r_reason_desc,
    RANK() OVER (ORDER BY ds.avg_purchase_estimate DESC) AS purchase_rank
FROM
    demo_stats ds
JOIN
    reason r
    ON 1 = 1
WHERE
    r.r_reason_desc IS NOT NULL
ORDER BY
    ds.avg_purchase_estimate DESC,
    ds.cust_cnt DESC
LIMIT 100
