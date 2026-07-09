WITH state_metrics AS (
    SELECT
        ca.ca_state AS state,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(2023 - c.c_birth_year) AS avg_age,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        SUM(hd.hd_dep_count) AS total_dependents
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND hd.hd_buy_potential = 'High'
      AND ca.ca_state IS NOT NULL
    GROUP BY ca.ca_state
)
SELECT
    state,
    num_customers,
    avg_age,
    avg_vehicle_count,
    total_dependents,
    age_rank
FROM (
    SELECT
        state,
        num_customers,
        avg_age,
        avg_vehicle_count,
        total_dependents,
        RANK() OVER (ORDER BY avg_age DESC) AS age_rank
    FROM state_metrics
) ranked
WHERE age_rank <= 5
ORDER BY age_rank
