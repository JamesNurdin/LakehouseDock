WITH reason_agg AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 0
    GROUP BY r.r_reason_desc
),
total_agg AS (
    SELECT
        SUM(total_net_loss) AS grand_total_net_loss
    FROM reason_agg
)
SELECT
    row_number() OVER (ORDER BY ra.total_net_loss DESC) AS reason_rank,
    ra.r_reason_desc,
    ra.return_count,
    ra.total_quantity,
    ra.total_return_amount,
    ra.total_net_loss,
    (ra.total_net_loss / ta.grand_total_net_loss) * 100.0 AS net_loss_pct
FROM reason_agg ra
CROSS JOIN total_agg ta
ORDER BY ra.total_net_loss DESC
LIMIT 10
