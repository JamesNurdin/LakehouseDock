-- Analytical query: Preferred‑customer profile by income band
WITH cust_hh AS (
    SELECT
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_buy_potential
    FROM customer c
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT ch.c_customer_sk)                           AS num_customers,
        AVG(ch.hd_vehicle_count)                                   AS avg_vehicle_count,
        approx_percentile(ch.hd_vehicle_count, 0.5)                AS median_vehicle_count,
        AVG(ch.hd_dep_count)                                       AS avg_dependency_count,
        SUM(CASE WHEN ch.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS num_preferred_customers,
        SUM(CASE WHEN ch.hd_buy_potential = 'HIGH'   THEN 1 ELSE 0 END) AS high_buy_potential_customers,
        SUM(CASE WHEN ch.hd_buy_potential = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_buy_potential_customers,
        SUM(CASE WHEN ch.hd_buy_potential = 'LOW'    THEN 1 ELSE 0 END) AS low_buy_potential_customers
    FROM cust_hh ch
    JOIN income_band ib
        ON ch.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ch.c_preferred_cust_flag = 'Y'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    num_customers,
    avg_vehicle_count,
    median_vehicle_count,
    avg_dependency_count,
    num_preferred_customers,
    high_buy_potential_customers,
    medium_buy_potential_customers,
    low_buy_potential_customers,
    ROW_NUMBER() OVER (ORDER BY num_customers DESC) AS rank_by_customers
FROM agg
ORDER BY ib_lower_bound
