SELECT
    ib_income_band_sk,
    income_range,
    num_customers,
    avg_vehicle_count,
    male_customers,
    female_customers,
    ROW_NUMBER() OVER (ORDER BY num_customers DESC) AS income_rank,
    SUM(num_customers) OVER (ORDER BY num_customers DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers
FROM (
    SELECT
        ib.ib_income_band_sk,
        CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS income_range,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        SUM(CASE WHEN c.c_salutation = 'Mr.' THEN 1 ELSE 0 END) AS male_customers,
        SUM(CASE WHEN c.c_salutation = 'Mrs.' THEN 1 ELSE 0 END) AS female_customers
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_email_address LIKE '%@%.com'
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING COUNT(DISTINCT c.c_customer_sk) >= 5
) sub
ORDER BY num_customers DESC
LIMIT 10
