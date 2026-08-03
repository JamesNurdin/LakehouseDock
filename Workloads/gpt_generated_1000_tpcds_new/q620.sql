WITH cr_sample AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10) -- sample 10% of rows
),
cr_agg AS (
    SELECT
        cr_returned_time_sk,
        SUM(cr_return_amount) AS sum_return_amount,
        AVG(cr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS cnt_returns
    FROM cr_sample
    GROUP BY cr_returned_time_sk
),
common_time_sk AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_meal_time = 'Breakfast'
    INTERSECT
    SELECT t_time_sk
    FROM time_dim
    WHERE t_shift = 'AM'
),
non_dinner_pm_time_sk AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_meal_time = 'Dinner'
    EXCEPT
    SELECT t_time_sk
    FROM time_dim
    WHERE t_shift = 'PM'
)
SELECT
    td.t_hour,
    td.t_minute,
    ca.sum_return_amount,
    ca.avg_return_quantity,
    ca.cnt_returns,
    (SELECT SUM(cr2.cr_return_ship_cost)
     FROM catalog_returns cr2
     WHERE cr2.cr_returned_time_sk = ca.cr_returned_time_sk) AS total_ship_cost_by_time
FROM cr_agg ca
JOIN time_dim td
  ON ca.cr_returned_time_sk = td.t_time_sk
WHERE ca.sum_return_amount > 1000
  AND ca.avg_return_quantity < 5
  AND ca.cnt_returns > 20
  AND td.t_second IN (3, 9, 11)
  AND td.t_minute IN (5, 10, 15)
  AND ca.cr_returned_time_sk IN (SELECT t_time_sk FROM common_time_sk)
  AND ca.cr_returned_time_sk NOT IN (SELECT t_time_sk FROM non_dinner_pm_time_sk)
UNION
SELECT
    td.t_hour,
    td.t_minute,
    ca.sum_return_amount,
    ca.avg_return_quantity,
    ca.cnt_returns,
    (SELECT SUM(cr2.cr_return_ship_cost)
     FROM catalog_returns cr2
     WHERE cr2.cr_returned_time_sk = ca.cr_returned_time_sk) AS total_ship_cost_by_time
FROM cr_agg ca
JOIN time_dim td
  ON ca.cr_returned_time_sk = td.t_time_sk
WHERE ca.sum_return_amount BETWEEN 500 AND 1500
  AND ca.avg_return_quantity BETWEEN 5 AND 10
  AND ca.cnt_returns > 10
  AND td.t_hour BETWEEN 12 AND 18
  AND td.t_second IN (14, 19)
  AND ca.cr_returned_time_sk IN (SELECT t_time_sk FROM common_time_sk)
LIMIT 100
