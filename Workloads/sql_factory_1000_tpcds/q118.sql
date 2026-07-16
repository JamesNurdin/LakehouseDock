WITH hour_category_stats AS (
    SELECT
        td.t_hour,
        i.i_category,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY td.t_hour, i.i_category
)
SELECT
    t_hour,
    i_category,
    total_return_qty,
    total_net_loss,
    DENSE_RANK() OVER (PARTITION BY t_hour ORDER BY total_net_loss DESC) AS category_net_loss_rank,
    SUM(total_net_loss) OVER (ORDER BY t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss_by_hour,
    LAG(total_net_loss) OVER (PARTITION BY i_category ORDER BY t_hour) AS prev_hour_net_loss,
    CASE
        WHEN LAG(total_net_loss) OVER (PARTITION BY i_category ORDER BY t_hour) IS NULL THEN 'N/A'
        WHEN total_net_loss > LAG(total_net_loss) OVER (PARTITION BY i_category ORDER BY t_hour) THEN 'Increase'
        ELSE 'Decrease'
    END AS net_loss_trend
FROM hour_category_stats
ORDER BY t_hour, category_net_loss_rank
