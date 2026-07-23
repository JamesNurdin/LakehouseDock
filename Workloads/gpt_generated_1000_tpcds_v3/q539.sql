WITH cust_hh_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        COUNT(*) AS customer_cnt,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_cnt,
        AVG(c.c_birth_year) AS avg_birth_year
    FROM
        tpcds.customer c
        JOIN tpcds.household_demographics hd
            ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1960 AND 2000
        AND c.c_preferred_cust_flag IN ('Y', 'N')
        AND c.c_birth_country = 'USA'
        AND c.c_current_hdemo_sk IN (1404, 4238, 3219, 7135, 89)
        AND hd.hd_dep_count >= 2
        AND hd.hd_vehicle_count >= 0
    GROUP BY
        hd.hd_demo_sk,
        hd.hd_buy_potential
)
SELECT
    hd_buy_potential,
    COUNT(*) AS num_groups,
    SUM(customer_cnt) AS total_customers,
    AVG(preferred_cnt) AS avg_preferred_per_group,
    AVG(avg_birth_year) AS avg_birth_year_across_groups
FROM cust_hh_agg
WHERE
    customer_cnt > 10
    AND preferred_cnt > 5
GROUP BY
    hd_buy_potential
ORDER BY
    total_customers DESC
LIMIT 100
