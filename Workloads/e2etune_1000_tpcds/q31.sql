SELECT
    state,
    total_customers,
    avg_vehicle_count,
    pct_high_buy_potential,
    RANK() OVER (ORDER BY total_customers DESC) AS state_rank,
    SUM(total_customers) OVER (ORDER BY total_customers DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers
FROM (
    SELECT
        ca.ca_state AS state,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        SUM(CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_high_buy_potential
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_year BETWEEN 1960 AND 2000
        AND c.c_last_review_date >= 2452500
    GROUP BY
        ca.ca_state
) AS agg
ORDER BY
    state_rank
