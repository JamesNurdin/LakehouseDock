WITH education_stats AS (
    SELECT
        hd.hd_buy_potential,
        cd.cd_education_status,
        COUNT(*) AS customer_cnt,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_dep_employed_count) AS avg_employed_deps,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY SUM(cd.cd_purchase_estimate) DESC) AS edu_rank
    FROM customer_demographics cd
    JOIN household_demographics hd
        ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND hd.hd_vehicle_count >= 1
      AND cd.cd_dep_employed_count > 0
    GROUP BY hd.hd_buy_potential, cd.cd_education_status
    HAVING COUNT(*) >= 10
)
SELECT
    hd_buy_potential,
    cd_education_status,
    customer_cnt,
    total_purchase_estimate,
    avg_employed_deps,
    edu_rank
FROM education_stats
WHERE edu_rank <= 3
ORDER BY hd_buy_potential, edu_rank
