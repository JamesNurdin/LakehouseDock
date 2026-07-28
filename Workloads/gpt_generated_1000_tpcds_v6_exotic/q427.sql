WITH morning_returns AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        t.t_meal_time AS meal_time,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 2000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_market_id IN (4, 6)
      AND t.t_shift = 'morning'
      AND t.t_meal_time = 'breakfast'
    GROUP BY s.s_store_id, s.s_store_name, t.t_meal_time
    HAVING SUM(sr.sr_return_amt) > 5000
),

evening_returns AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        t.t_meal_time AS meal_time,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 2000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_floor_space > 7500000
      AND t.t_shift = 'evening'
      AND t.t_meal_time = 'dinner'
    GROUP BY s.s_store_id, s.s_store_name, t.t_meal_time
    HAVING SUM(sr.sr_return_amt) > 5000
)
SELECT DISTINCT
    store_id,
    store_name,
    meal_time,
    total_return_amt,
    total_net_loss,
    loss_category,
    CASE WHEN loss_category = 'HIGH' AND total_return_amt > 10000 THEN 'ALERT' ELSE 'OK' END AS action_flag
FROM (
    SELECT * FROM morning_returns
    UNION ALL
    SELECT * FROM evening_returns
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
