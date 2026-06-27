WITH returns_by_time AS (
    SELECT
        td.t_hour,
        td.t_shift,
        td.t_meal_time,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY
        td.t_hour,
        td.t_shift,
        td.t_meal_time
)
SELECT
    t_hour,
    t_shift,
    t_meal_time,
    total_quantity,
    total_return_amount,
    total_net_loss,
    return_count,
    total_net_loss / NULLIF(total_return_amount, 0) AS net_loss_ratio,
    row_number() OVER (PARTITION BY t_meal_time ORDER BY total_net_loss DESC) AS rank_by_meal_time
FROM returns_by_time
ORDER BY t_hour, t_shift
