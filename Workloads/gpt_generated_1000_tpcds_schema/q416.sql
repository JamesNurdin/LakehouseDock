WITH sampled_customers AS (
    SELECT *
    FROM customer
    TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
),

agg1 AS (
    SELECT
        c.c_customer_id,
        COUNT(*) AS order_cnt,
        AVG(ib.ib_upper_bound) AS avg_upper_income,
        MIN(ib.ib_lower_bound) AS min_income,
        MAX(ib.ib_upper_bound) AS max_income
    FROM sampled_customers c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1970
      AND hd.hd_dep_count >= 2
      AND ib.ib_upper_bound <= 80000
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_last_review_date > 2451000
    GROUP BY c.c_customer_id
),

agg2 AS (
    SELECT
        c.c_customer_id,
        COUNT(*) AS order_cnt,
        AVG(ib.ib_upper_bound) AS avg_upper_income,
        MIN(ib.ib_lower_bound) AS min_income,
        MAX(ib.ib_upper_bound) AS max_income
    FROM sampled_customers c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
      AND hd.hd_vehicle_count = 2
      AND ib.ib_lower_bound >= 40000
      AND c.c_preferred_cust_flag = 'N'
      AND c.c_last_review_date < 2451500
    GROUP BY c.c_customer_id
),

union_agg AS (
    SELECT * FROM agg1
    UNION
    SELECT * FROM agg2
),

key_to_exclude AS (
    SELECT c.c_customer_id
    FROM customer c
    WHERE c.c_email_address LIKE '%@example.com'
),

except_set AS (
    SELECT u.c_customer_id, u.order_cnt, u.avg_upper_income, u.min_income, u.max_income
    FROM union_agg u
    EXCEPT
    SELECT k.c_customer_id, 0 AS order_cnt, 0.0 AS avg_upper_income, 0 AS min_income, 0 AS max_income
    FROM key_to_exclude k
),

final_result AS (
    SELECT e.*
    FROM except_set e
    WHERE e.c_customer_id NOT IN (
        SELECT c2.c_customer_id
        FROM customer c2
        WHERE c2.c_current_addr_sk IS NULL
    )
)
SELECT
    fr.c_customer_id,
    fr.order_cnt,
    fr.avg_upper_income,
    fr.min_income,
    fr.max_income
FROM final_result fr
ORDER BY fr.order_cnt DESC, fr.c_customer_id
LIMIT 100
