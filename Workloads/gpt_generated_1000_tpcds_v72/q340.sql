WITH overall AS (
    SELECT avg(sr_net_loss) AS overall_avg_net_loss
    FROM tpcds.store_returns
),
filtered AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_net_loss,
        sr.sr_addr_sk,
        t.t_meal_time,
        t.t_hour,
        t.t_time
    FROM tpcds.store_returns sr
    JOIN tpcds.time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_quantity > 10
      AND sr.sr_return_amt >= 20
      AND sr.sr_fee BETWEEN 1 AND 5
      AND sr.sr_addr_sk IN (726045, 1600118, 5883235)
      AND t.t_hour IN (8, 12, 19)
      AND t.t_meal_time IN ('breakfast', 'lunch', 'dinner')
)
SELECT
    f.t_meal_time,
    SUM(f.sr_net_loss) AS total_net_loss,
    AVG(f.sr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt,
    CASE
        WHEN SUM(f.sr_net_loss) > o.overall_avg_net_loss * 5 THEN 'High'
        ELSE 'Normal'
    END AS loss_category,
    RANK() OVER (ORDER BY SUM(f.sr_net_loss) DESC) AS loss_rank
FROM filtered f
CROSS JOIN overall o
GROUP BY f.t_meal_time, o.overall_avg_net_loss
ORDER BY loss_rank ASC, f.t_meal_time
