WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returning_cdemo_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_cash,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_reason_sk,
        wr.wr_order_number,
        r.r_reason_desc,
        r.r_reason_id
    FROM web_returns wr
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returning_cdemo_sk IN (908769, 869116, 1664039, 534510, 1152484)
      AND wr.wr_refunded_cash > 200
      AND wr.wr_return_quantity >= 1
      AND wr.wr_return_quantity <= 3
      AND wr.wr_return_amt < 400
      AND r.r_reason_id = 'AAAAAAAACAAAAAAA'
),
aggregated AS (
    SELECT
        fr.r_reason_desc,
        fr.wr_reason_sk,
        COUNT(*) AS return_cnt,
        SUM(fr.wr_refunded_cash) AS total_refunded_cash,
        AVG(fr.wr_return_amt) AS avg_return_amt,
        MIN(fr.wr_return_amt) AS min_return_amt,
        MAX(fr.wr_return_amt) AS max_return_amt,
        (
            SELECT AVG(wr2.wr_refunded_cash)
            FROM web_returns wr2
            WHERE wr2.wr_reason_sk = fr.wr_reason_sk
        ) AS avg_refunded_cash_all_reason
    FROM filtered_returns fr
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr3
        WHERE wr3.wr_order_number = fr.wr_order_number
          AND wr3.wr_return_quantity > 10
    )
    GROUP BY fr.r_reason_desc, fr.wr_reason_sk
)
SELECT
    a.r_reason_desc,
    a.return_cnt,
    a.total_refunded_cash,
    a.avg_return_amt,
    a.min_return_amt,
    a.max_return_amt,
    a.avg_refunded_cash_all_reason,
    ROW_NUMBER() OVER (PARTITION BY a.r_reason_desc ORDER BY a.total_refunded_cash DESC) AS reason_rank
FROM aggregated a
ORDER BY a.total_refunded_cash DESC
LIMIT 100
