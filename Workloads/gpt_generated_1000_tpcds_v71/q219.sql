WITH hd_agg AS (
    SELECT
        hd_demo_sk,
        hd_buy_potential,
        AVG(hd_vehicle_count) AS avg_vehicle_cnt,
        MAX(hd_dep_count) AS max_dep_cnt,
        COUNT(*) AS hd_cnt
    FROM household_demographics
    WHERE hd_vehicle_count >= 1
      AND hd_dep_count <> 0
      AND hd_buy_potential IN ('5001-10000', '>10000', '1001-5000')
    GROUP BY hd_demo_sk, hd_buy_potential
),
potential_list AS (
    SELECT hd_buy_potential FROM household_demographics WHERE hd_vehicle_count >= 2
    UNION
    SELECT hd_buy_potential FROM household_demographics WHERE hd_dep_count > 5
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_day,
    c.c_birth_month,
    hd.hd_buy_potential,
    hd.avg_vehicle_cnt,
    hd.max_dep_cnt,
    (SELECT MAX(hd2.hd_dep_count) FROM household_demographics hd2) AS overall_max_dep_cnt,
    COUNT(*) OVER (PARTITION BY hd.hd_buy_potential) AS custs_per_potential,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY c.c_last_name) AS rn
FROM customer c
JOIN hd_agg hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE c.c_birth_year = 1990
  AND c.c_birth_month = 8
  AND c.c_birth_day = 11
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_salutation = 'Mr.'
  AND c.c_last_review_date > 20220101
  AND hd.hd_buy_potential IN (SELECT hd_buy_potential FROM potential_list)
  AND NOT EXISTS (
        SELECT 1
        FROM household_demographics hd_ex
        WHERE hd_ex.hd_demo_sk = c.c_current_hdemo_sk
          AND hd_ex.hd_vehicle_count = 0
    )
  AND c.c_customer_id IN (
        SELECT c2.c_customer_id
        FROM customer c2
        WHERE c2.c_first_name = 'Albert'
          AND c2.c_last_name = 'Fonda'
    )
ORDER BY hd.hd_buy_potential, c.c_last_name
LIMIT 100
