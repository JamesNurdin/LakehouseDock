WITH filtered AS (
    SELECT
        c.c_customer_id,
        c.c_birth_year,
        c.c_email_address,
        hd.hd_demo_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN hd.hd_vehicle_count >= 2 THEN 'MultiVehicle' ELSE 'LowVehicle' END AS vehicle_category
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count >= 5                     -- predicate 1
      AND hd.hd_vehicle_count >= 0                 -- predicate 2
      AND ib.ib_lower_bound >= 80000               -- predicate 3
      AND c.c_birth_year BETWEEN 1970 AND 1990    -- predicate 4
      AND c.c_email_address LIKE '%@%.com'        -- predicate 5
),
agg AS (
    SELECT
        f.vehicle_category,
        f.ib_income_band_sk,
        COUNT(*) AS cust_cnt,
        AVG(f.hd_vehicle_count) AS avg_vehicles,
        SUM(CASE WHEN f.c_birth_year < 1980 THEN 1 ELSE 0 END) AS cnt_before_1980
    FROM filtered f
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.customer c2
        WHERE c2.c_current_hdemo_sk = f.hd_demo_sk
          AND c2.c_preferred_cust_flag = 'Y'
    )
    GROUP BY f.vehicle_category, f.ib_income_band_sk
    HAVING COUNT(*) >= 10
)
SELECT
    vehicle_category,
    ib_income_band_sk,
    cust_cnt,
    avg_vehicles,
    cnt_before_1980,
    RANK() OVER (ORDER BY avg_vehicles DESC) AS vehicle_rank,
    SUM(cust_cnt) OVER (
        PARTITION BY vehicle_category
        ORDER BY ib_income_band_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_cust_by_income
FROM agg
ORDER BY vehicle_rank ASC, ib_income_band_sk
