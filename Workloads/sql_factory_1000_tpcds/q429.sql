WITH shift_agg AS (
    SELECT
        td.t_shift,
        COALESCE(SUM(sr.sr_net_loss), 0) AS store_net_loss,
        COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_loss,
        COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss
    FROM time_dim td
    LEFT JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_shift
)
SELECT
    t_shift,
    store_net_loss,
    web_net_loss,
    total_net_loss,
    DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS total_loss_rank,
    CASE
        WHEN total_net_loss > 50000 THEN 'VERY HIGH'
        WHEN total_net_loss > 25000 THEN 'HIGH'
        WHEN total_net_loss > 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS total_loss_category,
    SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC) / SUM(total_net_loss) OVER () * 100 AS cumulative_pct
FROM shift_agg
ORDER BY total_loss_rank
