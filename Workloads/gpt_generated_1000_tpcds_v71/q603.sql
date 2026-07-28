/*
  Goal: Summarize web return activity by hour of day and meal time, then filter to the most significant periods.
*/
WITH hourly_returns AS (
    SELECT
        td.t_hour AS hour,
        td.t_meal_time AS meal_time,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(wr.wr_account_credit) AS avg_account_credit,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN time_dim td
      ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 6 AND 22                -- business hours
      AND td.t_meal_time IN ('breakfast','lunch','dinner')
      AND wr.wr_return_quantity > 0               -- only actual returns
      AND wr.wr_return_amt_inc_tax > 50.00        -- sizable returns
      AND wr.wr_account_credit BETWEEN 10.00 AND 500.00
      AND wr.wr_net_loss > 0
    GROUP BY td.t_hour, td.t_meal_time
)
SELECT
    hour,
    meal_time,
    return_cnt,
    total_return_inc_tax,
    avg_account_credit,
    total_net_loss,
    total_return_inc_tax / return_cnt AS avg_return_inc_tax_per_return
FROM hourly_returns
WHERE return_cnt >= 10                -- enough transactions to be meaningful
  AND total_net_loss > 1000.00          -- focus on periods with notable loss
ORDER BY total_return_inc_tax DESC
LIMIT 100
