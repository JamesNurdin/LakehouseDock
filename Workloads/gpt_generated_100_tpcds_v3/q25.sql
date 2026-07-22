WITH hd_agg AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_buy_potential,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        SUM(hd_dep_count) AS total_dep_count,
        COUNT(*) AS hd_records
    FROM household_demographics
    WHERE hd_vehicle_count >= 0
      AND hd_dep_count BETWEEN 0 AND 10
      AND hd_buy_potential IS NOT NULL
    GROUP BY hd_demo_sk, hd_income_band_sk, hd_buy_potential
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    hd_agg.hd_buy_potential,
    hd_agg.avg_vehicle_count,
    hd_agg.total_dep_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    RANK() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY c.c_birth_year DESC) AS birth_year_rank,
    ROW_NUMBER() OVER (PARTITION BY hd_agg.hd_buy_potential ORDER BY hd_agg.avg_vehicle_count DESC) AS vehicle_count_rownum,
    CASE
        WHEN ib.ib_upper_bound <= 20000 THEN 'Low'
        WHEN ib.ib_upper_bound <= 100000 THEN 'Medium'
        ELSE 'High'
    END AS income_category
FROM customer c
JOIN hd_agg
    ON c.c_current_hdemo_sk = hd_agg.hd_demo_sk
JOIN income_band ib
    ON hd_agg.hd_income_band_sk = ib.ib_income_band_sk
WHERE c.c_birth_year BETWEEN 1950 AND 2000
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_last_review_date IS NOT NULL
  AND c.c_birth_month IN (1, 2, 3, 4, 5, 6)
ORDER BY income_category, birth_year_rank, c.c_customer_id
LIMIT 100
