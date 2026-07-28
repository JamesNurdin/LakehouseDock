WITH cust_hh AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day,
        c.c_preferred_cust_flag,
        c.c_first_shipto_date_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_first_shipto_date_sk BETWEEN 2450540 AND 2452253
      AND c.c_birth_year BETWEEN 1970 AND 1995
      AND c.c_birth_month IN (1, 2, 3, 4, 5, 6)
      AND c.c_birth_day IN (10, 12, 22, 23, 28)
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_dep_count <= 5
      AND hd.hd_buy_potential IN ('0-500', '501-1000', '5001-10000')
), agg AS (
    SELECT
        hd_buy_potential,
        COUNT(DISTINCT c_customer_sk) AS customer_cnt,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        MIN(c_birth_year) AS min_birth_year,
        MAX(c_birth_year) AS max_birth_year,
        SUM(c_first_shipto_date_sk) AS sum_shipto_key
    FROM cust_hh
    GROUP BY hd_buy_potential
)
SELECT
    hd_buy_potential,
    customer_cnt,
    avg_vehicle_count,
    min_birth_year,
    max_birth_year,
    sum_shipto_key,
    SUM(customer_cnt) OVER (
        PARTITION BY hd_buy_potential
        ORDER BY customer_cnt DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_customer_cnt,
    RANK() OVER (ORDER BY customer_cnt DESC) AS rank_by_customers
FROM agg
ORDER BY customer_cnt DESC
LIMIT 100
