WITH filtered_customers AS (
    SELECT
        c.c_customer_id,
        c.c_birth_month,
        c.c_last_review_date,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_month IN (1, 7, 12)
      AND c.c_last_review_date > 2452400
      AND cd.cd_dep_count >= 2
      AND cd.cd_purchase_estimate BETWEEN 2000 AND 9000
      AND hd.hd_income_band_sk IN (12, 13, 17)
      AND hd.hd_buy_potential = '>10000'
)
SELECT
    fc.c_birth_month,
    fc.cd_gender,
    fc.hd_buy_potential,
    COUNT(DISTINCT fc.c_customer_id) AS unique_customers,
    SUM(fc.cd_purchase_estimate) AS total_purchase_estimate,
    AVG(fc.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(fc.c_last_review_date) AS earliest_review_date,
    MAX(fc.c_last_review_date) AS latest_review_date,
    (SELECT MAX(hd2.hd_vehicle_count) FROM tpcds.household_demographics hd2) AS max_vehicle_overall
FROM filtered_customers fc
GROUP BY fc.c_birth_month, fc.cd_gender, fc.hd_buy_potential
HAVING COUNT(DISTINCT fc.c_customer_id) >= 5
ORDER BY total_purchase_estimate DESC
LIMIT 100
