WITH high_income_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 150000
)
SELECT
    'Breakfast' AS meal_category,
    td.t_meal_time,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_return_time_sk = td.t_time_sk
    ) AS avg_return_amt_for_time
FROM store_returns sr
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
WHERE td.t_meal_time = 'breakfast'
  AND c.c_customer_sk IN (SELECT c_customer_sk FROM high_income_customers)
GROUP BY td.t_meal_time, td.t_time_sk
HAVING SUM(sr.sr_net_loss) > 1000
UNION ALL
SELECT
    'Dinner' AS meal_category,
    td.t_meal_time,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_return_time_sk = td.t_time_sk
    ) AS avg_return_amt_for_time
FROM store_returns sr
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
WHERE td.t_meal_time = 'dinner'
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
          AND ib.ib_upper_bound >= 150000
    )
GROUP BY td.t_meal_time, td.t_time_sk
HAVING SUM(sr.sr_net_loss) > 1000
ORDER BY meal_category, total_net_loss DESC
