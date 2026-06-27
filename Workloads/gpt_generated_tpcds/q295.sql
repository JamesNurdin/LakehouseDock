WITH group_stats AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        COUNT(*) AS total_customers,
        AVG(2026 - c.c_birth_year) AS avg_age
    FROM
        customer c
        JOIN household_demographics hd
            ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
    GROUP BY
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
)
SELECT
    hd_income_band_sk,
    hd_buy_potential,
    hd_dep_count,
    hd_vehicle_count,
    total_customers,
    avg_age,
    SUM(total_customers) OVER (ORDER BY total_customers DESC ROWS UNBOUNDED PRECEDING) AS cumulative_customers,
    RANK() OVER (ORDER BY total_customers DESC) AS rank_by_customers
FROM
    group_stats
ORDER BY
    total_customers DESC
LIMIT 10
