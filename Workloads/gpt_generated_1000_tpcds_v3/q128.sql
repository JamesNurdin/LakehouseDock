WITH hd_agg AS (
    SELECT
        hd_demo_sk,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        SUM(hd_dep_count) AS total_dep_count,
        MAX(hd_income_band_sk) AS max_income_band_sk
    FROM household_demographics
    WHERE hd_dep_count >= 0
      AND hd_vehicle_count >= 0
      AND hd_income_band_sk IN (1, 2, 3, 4)
    GROUP BY hd_demo_sk
),
cust_agg AS (
    SELECT
        c_current_hdemo_sk,
        COUNT(*) AS customer_cnt,
        COUNT(DISTINCT c_customer_id) AS distinct_customer_cnt,
        AVG(c_birth_year) AS avg_birth_year,
        MAX(c_last_review_date) AS max_last_review_date
    FROM customer
    WHERE c_birth_year >= 1970
      AND c_birth_year <= 2000
      AND c_birth_month BETWEEN 1 AND 6
      AND c_preferred_cust_flag = 'Y'
      AND c_last_review_date > 2452400
    GROUP BY c_current_hdemo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.avg_vehicle_count,
    hd.total_dep_count,
    hd.max_income_band_sk,
    ca.customer_cnt,
    ca.distinct_customer_cnt,
    ca.avg_birth_year,
    ca.max_last_review_date
FROM hd_agg hd
JOIN cust_agg ca
    ON ca.c_current_hdemo_sk = hd.hd_demo_sk
WHERE hd.avg_vehicle_count > (
    SELECT AVG(avg_vehicle_count) FROM hd_agg
)
  AND EXISTS (
    SELECT 1 FROM household_demographics hd2
    WHERE hd2.hd_demo_sk = hd.hd_demo_sk
      AND hd2.hd_buy_potential = 'HIGH'
)
  AND ca.c_current_hdemo_sk IN (
    SELECT DISTINCT hd_demo_sk FROM household_demographics
    WHERE hd_buy_potential = 'HIGH'
)
ORDER BY ca.distinct_customer_cnt DESC, hd.avg_vehicle_count ASC
LIMIT 100
