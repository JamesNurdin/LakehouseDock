WITH wr_array AS (
  SELECT
    wr_returned_time_sk,
    wr_return_quantity,
    wr_return_amt,
    wr_return_ship_cost,
    wr_returned_date_sk,
    ARRAY[wr_return_quantity, wr_return_amt] AS qty_amt_arr
  FROM web_returns
  WHERE wr_return_ship_cost > 100
    AND wr_return_quantity >= 1
    AND wr_return_amt BETWEEN 10 AND 500
),
expanded AS (
  SELECT
    wr_returned_time_sk,
    wr_return_quantity,
    wr_return_amt,
    wr_return_ship_cost,
    metric_value
  FROM wr_array
  CROSS JOIN UNNEST(qty_amt_arr) AS t(metric_value)
),
agg1 AS (
  SELECT
    td.t_hour,
    td.t_am_pm,
    SUM(expanded.metric_value) AS sum_metric,
    COUNT(*) AS cnt_rows,
    SUM(CASE WHEN expanded.metric_value > 200 THEN 1 ELSE 0 END) AS cnt_large_metric
  FROM expanded
  FULL OUTER JOIN time_dim td
    ON expanded.wr_returned_time_sk = td.t_time_sk
  WHERE td.t_hour IS NOT NULL
    AND (td.t_am_pm = 'AM' OR td.t_am_pm = 'PM')
    AND td.t_shift = 'Morning'
  GROUP BY td.t_hour, td.t_am_pm
  HAVING SUM(expanded.metric_value) > 1000
)
SELECT
  t_hour,
  t_am_pm,
  sum_metric,
  cnt_rows,
  cnt_large_metric,
  CASE
    WHEN cnt_large_metric > (cnt_rows / 2) THEN 'Majority Large'
    ELSE 'Minority Large'
  END AS metric_category
FROM agg1
ORDER BY sum_metric DESC
LIMIT 100
