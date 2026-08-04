WITH agg AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(w.wr_return_amt) AS sum_return_amt,
        AVG(w.wr_fee) AS avg_fee,
        MIN(w.wr_return_quantity) AS min_qty,
        MAX(w.wr_net_loss) AS max_net_loss
    FROM web_returns w
    JOIN reason r ON w.wr_reason_sk = r.r_reason_sk
    WHERE w.wr_return_amt > 50
      AND w.wr_fee BETWEEN 10 AND 100
      AND w.wr_return_quantity <= 5
      AND w.wr_account_credit > 20
      AND w.wr_returning_cdemo_sk IN (1360384, 1696824, 1781163)
      AND r.r_reason_id = 'AAAAAAAAABAAAAAA'
      AND EXISTS (
          SELECT 1 FROM web_returns w2
          WHERE w2.wr_reason_sk = r.r_reason_sk
            AND w2.wr_return_amt > 200
      )
    GROUP BY r.r_reason_id, r.r_reason_desc
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY sum_return_amt DESC) AS rn
    FROM agg
)
SELECT
    r_reason_id,
    r_reason_desc,
    cnt_returns,
    sum_return_amt,
    avg_fee,
    min_qty,
    max_net_loss
FROM ranked
WHERE rn <= 3
ORDER BY sum_return_amt DESC
LIMIT 100
