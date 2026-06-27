WITH aggregated AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS total_returns,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amount,
        SUM(sr.sr_fee) AS total_fee,
        MAX(sr.sr_return_amt_inc_tax) AS max_return_amount_inc_tax
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 0
    GROUP BY r.r_reason_desc
)
SELECT
    a.r_reason_desc,
    a.total_returns,
    a.total_net_loss,
    a.avg_return_amount,
    a.total_fee,
    a.max_return_amount_inc_tax,
    ROW_NUMBER() OVER (ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 10
