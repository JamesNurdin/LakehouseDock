/* goal: Identify the most populous customer groups by income band and vehicle count, using recent sales and review activity, and rank groups within each income band */
WITH filtered_customers AS (
    SELECT DISTINCT
        c_customer_sk,
        c_current_hdemo_sk,
        c_birth_day,
        c_preferred_cust_flag,
        c_first_sales_date_sk,
        c_last_review_date
    FROM tpcds.customer
    WHERE c_first_sales_date_sk BETWEEN 2450000 AND 2452000
      AND c_last_review_date > 2452400
      AND c_preferred_cust_flag = 'Y'
),
agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        COUNT(DISTINCT fc.c_customer_sk) AS num_customers,
        AVG(fc.c_birth_day) AS avg_birth_day
    FROM filtered_customers fc
    JOIN tpcds.household_demographics hd
        ON fc.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 0
      AND ib.ib_upper_bound <= 200000
    GROUP BY GROUPING SETS (
        (ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_vehicle_count),
        (ib.ib_lower_bound, ib.ib_upper_bound),
        ()
    )
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_vehicle_count,
    num_customers,
    avg_birth_day,
    RANK() OVER (PARTITION BY ib_lower_bound, ib_upper_bound ORDER BY num_customers DESC) AS rank_within_income_band
FROM agg
WHERE num_customers IS NOT NULL
ORDER BY ib_lower_bound, ib_upper_bound, hd_vehicle_count
LIMIT 100
