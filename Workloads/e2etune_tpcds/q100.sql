WITH aggregated AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        d.d_month_seq AS month_seq,
        COUNT(*) AS customer_cnt,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_est,
        SUM(cd.cd_purchase_estimate) AS total_purchase_est
    FROM
        customer_demographics cd
        JOIN date_dim d
            ON (cd.cd_demo_sk % 31) = (d.d_date_sk % 31)
    WHERE
        cd.cd_credit_rating = 'Good'
        AND d.d_year = 2023
        AND cd.cd_dep_count >= 1
    GROUP BY
        cd.cd_gender,
        cd.cd_education_status,
        d.d_month_seq
    HAVING
        COUNT(*) > 10
)
SELECT
    gender,
    education_status,
    month_seq,
    customer_cnt,
    avg_purchase_est,
    total_purchase_est,
    RANK() OVER (PARTITION BY month_seq ORDER BY avg_purchase_est DESC) AS rank_by_avg
FROM
    aggregated
ORDER BY
    month_seq,
    rank_by_avg
LIMIT 100
