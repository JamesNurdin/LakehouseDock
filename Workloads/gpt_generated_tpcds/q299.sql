WITH return_agg AS (
    SELECT
        wr.wr_reason_sk,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        AVG(wr.wr_net_loss) AS avg_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
    GROUP BY wr.wr_reason_sk
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    a.total_returns,
    a.total_quantity,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_amount,
    a.avg_net_loss,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM return_agg a
JOIN reason r
    ON a.wr_reason_sk = r.r_reason_sk
ORDER BY net_loss_rank
LIMIT 10
