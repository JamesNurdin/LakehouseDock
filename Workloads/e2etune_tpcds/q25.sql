WITH reason_agg AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2450999
      AND wr.wr_return_amt > 100
    GROUP BY r.r_reason_desc
)
SELECT
    r_reason_desc,
    total_returns,
    total_quantity,
    total_return_amount,
    avg_return_amount,
    total_net_loss,
    ROUND(100.0 * total_return_amount / SUM(total_return_amount) OVER (), 2) AS pct_of_total_return_amount,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    SUM(total_return_amount) OVER (ORDER BY total_return_amount DESC ROWS UNBOUNDED PRECEDING) AS cumulative_return_amount
FROM reason_agg
ORDER BY net_loss_rank
