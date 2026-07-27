WITH loss_metric AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        'total_net_loss' AS metric_name,
        SUM(wr.wr_net_loss) AS metric_value
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_net_loss > 0
    GROUP BY r.r_reason_id, r.r_reason_desc
),
ship_metric AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        'avg_ship_cost' AS metric_name,
        AVG(wr.wr_return_ship_cost) AS metric_value
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_ship_cost > 100
    GROUP BY r.r_reason_id, r.r_reason_desc
)
SELECT
    combined.r_reason_id,
    combined.r_reason_desc,
    combined.metric_name,
    combined.metric_value
FROM (
    SELECT * FROM loss_metric
    UNION ALL
    SELECT * FROM ship_metric
) AS combined
ORDER BY combined.metric_value DESC, combined.r_reason_id
LIMIT 100
