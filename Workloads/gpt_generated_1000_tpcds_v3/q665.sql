WITH state_income_agg AS (
    SELECT
        ca.ca_state AS state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN hd.hd_vehicle_count > 0 THEN hd.hd_vehicle_count ELSE 0 END) AS total_vehicle_count,
        AVG(hd.hd_dep_count) AS avg_dependents,
        SUM(
            CASE 
                WHEN hd.hd_buy_potential = '0-500' THEN 1
                WHEN hd.hd_buy_potential = '1001-5000' THEN 2
                WHEN hd.hd_buy_potential = '5001-10000' THEN 3
                WHEN hd.hd_buy_potential = '>10000' THEN 4
                ELSE 0
            END
        ) AS buy_potential_score
    FROM
        tpcds.customer c
        INNER JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        INNER JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        INNER JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        INNER JOIN tpcds.date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    WHERE
        ca.ca_gmt_offset = -5.00
        AND d_ship.d_year = 2000
        AND ib.ib_upper_bound >= 100000
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        ca.ca_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    sai.state,
    SUM(sai.customer_count) AS total_customers,
    SUM(sai.total_vehicle_count) AS total_vehicles,
    AVG(sai.avg_dependents) AS avg_dependents_across_income_bands,
    CASE 
        WHEN SUM(sai.buy_potential_score) >= (SELECT AVG(buy_potential_score) FROM state_income_agg) THEN 'HighPotential'
        ELSE 'LowPotential'
    END AS potential_category
FROM
    state_income_agg sai
WHERE
    sai.customer_count > 50
GROUP BY
    sai.state
HAVING
    SUM(sai.customer_count) > 100
    AND AVG(sai.avg_dependents) > 2.0
ORDER BY
    total_customers DESC,
    sai.state
LIMIT 100
