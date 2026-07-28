WITH filtered AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN hd.hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END AS vehicle_status
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count >= 1
      AND hd.hd_vehicle_count >= 0
      AND ib.ib_lower_bound >= 60000
      AND c.c_last_review_date >= 2452450
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    hd_buy_potential,
    vehicle_status,
    ib_lower_bound,
    ib_upper_bound,
    RANK() OVER (PARTITION BY vehicle_status ORDER BY ib_upper_bound DESC) AS income_rank,
    ROW_NUMBER() OVER (ORDER BY ib_upper_bound DESC) AS overall_rank
FROM filtered
ORDER BY overall_rank
LIMIT 100
