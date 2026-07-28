WITH cust_joined AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_zip AS zip,
        hd.hd_buy_potential AS buy_potential,
        hd.hd_dep_count AS dep_count,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1980
        AND c.c_preferred_cust_flag = 'Y'
        AND ca.ca_state = 'CA'
        AND ca.ca_zip LIKE '9%'
        AND hd.hd_buy_potential = '5001-10000'
        AND hd.hd_dep_count >= 2
        AND ib.ib_upper_bound <= 100000
)
SELECT
    customer_id,
    first_name,
    last_name,
    city,
    state,
    zip,
    buy_potential,
    dep_count,
    lower_bound,
    upper_bound,
    CASE
        WHEN upper_bound > 80000 THEN 'High'
        WHEN upper_bound BETWEEN 50001 AND 80000 THEN 'Medium'
        ELSE 'Low'
    END AS income_category,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY upper_bound DESC) AS income_rank_state
FROM cust_joined
ORDER BY state, income_rank_state
LIMIT 100
