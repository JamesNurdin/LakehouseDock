WITH cust AS (
    SELECT c.*
    FROM tpcds.customer c
    WHERE c.c_email_address LIKE '%@%com'
      AND c.c_last_review_date > 2452300
      AND c.c_current_hdemo_sk IN (
          SELECT hd.hd_demo_sk
          FROM tpcds.household_demographics hd
          WHERE hd.hd_buy_potential = '>10000'
      )
),
hd AS (
    SELECT hd.*
    FROM tpcds.household_demographics hd
    WHERE hd.hd_dep_count BETWEEN 1 AND 5
      AND hd.hd_income_band_sk IN (
          SELECT ib.ib_income_band_sk
          FROM tpcds.income_band ib
          WHERE ib.ib_upper_bound <= 100000
      )
)
SELECT 
    CASE WHEN ib.ib_upper_bound > 90000 THEN 'High' ELSE 'Medium' END AS income_category,
    hd.hd_buy_potential,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(c.c_birth_year) AS avg_birth_year,
    MIN(c.c_birth_year) AS min_birth_year,
    MAX(c.c_birth_year) AS max_birth_year,
    MAX(ib_max.max_income_upper) AS max_income_upper
FROM cust c
JOIN hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN LATERAL (
    SELECT MAX(ib2.ib_upper_bound) AS max_income_upper
    FROM tpcds.income_band ib2
    WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
) ib_max
GROUP BY 
    CASE WHEN ib.ib_upper_bound > 90000 THEN 'High' ELSE 'Medium' END,
    hd.hd_buy_potential
ORDER BY distinct_customers DESC
LIMIT 100
