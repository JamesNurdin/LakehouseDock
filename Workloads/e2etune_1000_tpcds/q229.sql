WITH cust_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk
    FROM customer c
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1950 AND 1970
)
SELECT
    birth_year,
    buy_potential,
    num_customers,
    avg_vehicle_count,
    median_vehicle_count,
    distinct_income_bands,
    RANK() OVER (PARTITION BY birth_year ORDER BY avg_vehicle_count DESC) AS vehicle_rank
FROM (
    SELECT
        c_birth_year AS birth_year,
        hd_buy_potential AS buy_potential,
        COUNT(*) AS num_customers,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        approx_percentile(hd_vehicle_count, 0.5) AS median_vehicle_count,
        COUNT(DISTINCT hd_income_band_sk) AS distinct_income_bands
    FROM cust_demo
    GROUP BY c_birth_year, hd_buy_potential
    HAVING COUNT(*) >= 5
) agg
ORDER BY birth_year, vehicle_rank
LIMIT 200
