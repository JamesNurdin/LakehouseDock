/* goal: Compare the average return amount for the 'first' shift with the total return quantity for the 'second' shift, include the overall maximum return amount, rank each result within its shift, and return the top rows */
WITH first_shift AS (
    SELECT
        td.t_shift AS shift,
        AVG(wr.wr_return_amt) AS metric_value,
        (SELECT MAX(wr2.wr_return_amt) FROM web_returns wr2) AS max_return_amt_overall
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
      AND EXISTS (
          SELECT 1 FROM web_returns wr3
          WHERE wr3.wr_item_sk = wr.wr_item_sk
            AND wr3.wr_return_amt > 50
      )
    GROUP BY td.t_shift
),
second_shift AS (
    SELECT
        td.t_shift AS shift,
        SUM(wr.wr_return_quantity) AS metric_value,
        (SELECT MAX(wr2.wr_return_amt) FROM web_returns wr2) AS max_return_amt_overall
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'second'
      AND EXISTS (
          SELECT 1 FROM web_returns wr3
          WHERE wr3.wr_item_sk = wr.wr_item_sk
            AND wr3.wr_return_amt > 75
      )
    GROUP BY td.t_shift
)
SELECT
    shift,
    metric_value,
    ROW_NUMBER() OVER (PARTITION BY shift ORDER BY metric_value DESC) AS rn,
    max_return_amt_overall
FROM first_shift
UNION ALL
SELECT
    shift,
    metric_value,
    ROW_NUMBER() OVER (PARTITION BY shift ORDER BY metric_value DESC) AS rn,
    max_return_amt_overall
FROM second_shift
ORDER BY metric_value DESC
LIMIT 100
