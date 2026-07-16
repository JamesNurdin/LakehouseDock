WITH cust_demo AS (
    SELECT
        ca.ca_state,
        hd.hd_buy_potential,
        COUNT(*) AS num_customers,
        AVG(c.c_birth_year) AS avg_birth_year,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cust_cnt
    FROM customer c
    JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 2000
      AND ca.ca_state IS NOT NULL
    GROUP BY ca.ca_state, hd.hd_buy_potential
    HAVING COUNT(*) >= 20
)
SELECT
    ca_state,
    hd_buy_potential,
    num_customers,
    avg_birth_year,
    avg_vehicle_count,
    pref_cust_cnt,
    (SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_type = 'monthly') AS monthly_page_cnt,
    (SELECT SUM(p.p_cost) FROM promotion p WHERE p.p_discount_active = 'Y') AS total_active_promo_cost,
    RANK() OVER (ORDER BY num_customers DESC) AS state_buy_potential_rank
FROM cust_demo
ORDER BY num_customers DESC
LIMIT 100
