WITH morning_returns AS (
    SELECT
        s.s_store_name AS store_name,
        'Morning' AS period,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(DISTINCT sr.sr_return_amt) AS distinct_return_amount,
        (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE t.t_hour < 12
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_desc = 'Damaged'
            AND r2.r_reason_sk = sr.sr_reason_sk
      )
    GROUP BY s.s_store_name
),
afternoon_returns AS (
    SELECT
        s.s_store_name AS store_name,
        'Afternoon' AS period,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(DISTINCT sr.sr_return_amt) AS distinct_return_amount,
        (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE t.t_hour >= 12
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_desc = 'Customer Not Satisfied'
            AND r2.r_reason_sk = sr.sr_reason_sk
      )
    GROUP BY s.s_store_name
)
SELECT store_name,
       period,
       distinct_customers,
       distinct_return_amount,
       max_income_upper
FROM morning_returns
UNION ALL
SELECT store_name,
       period,
       distinct_customers,
       distinct_return_amount,
       max_income_upper
FROM afternoon_returns
ORDER BY store_name, period
LIMIT 100
