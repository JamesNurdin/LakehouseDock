WITH daily_hourly AS (
    SELECT
        d.d_date,
        t.t_hour,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    GROUP BY d.d_date, t.t_hour
)
SELECT
    d_date,
    t_hour,
    total_returns,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    CASE
        WHEN total_return_amount > 10000 THEN 'HIGH'
        WHEN total_return_amount > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_amount_category,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    SUM(total_net_loss) OVER (PARTITION BY d_date ORDER BY t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss_by_hour
FROM daily_hourly
ORDER BY d_date, t_hour
