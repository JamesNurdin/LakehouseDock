WITH filtered_returns AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_returned_date_sk,
        sr.sr_reason_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 10
      AND sr.sr_return_quantity > 0
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
),
reason_stats AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(fr.sr_return_amt) AS total_return_amt,
        SUM(fr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        AVG(fr.sr_return_quantity) AS avg_return_qty,
        SUM(fr.sr_net_loss) AS total_net_loss
    FROM filtered_returns fr
    JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
    HAVING COUNT(*) >= 5
)
SELECT
    reason_desc,
    cnt_returns,
    total_return_amt,
    total_return_amt_inc_tax,
    avg_return_qty,
    total_net_loss,
    total_return_amt / cnt_returns AS avg_return_amt_per_return,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_amt_rank
FROM reason_stats
ORDER BY return_amt_rank
LIMIT 20
