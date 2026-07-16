WITH reason_agg AS (
    SELECT
        r.r_reason_desc AS r_desc,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_quantity
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND sr.sr_return_amt > 0
    GROUP BY r.r_reason_desc
    HAVING SUM(sr.sr_return_amt) > 5000
)
SELECT
    r_desc,
    total_returns,
    total_return_amount,
    total_net_loss,
    avg_quantity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM reason_agg
ORDER BY net_loss_rank
LIMIT 5
