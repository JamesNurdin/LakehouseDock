WITH reason_agg AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM tpcds.web_returns wr
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_refunded_hdemo_sk IN (2641, 4276, 3197)
    GROUP BY r.r_reason_id, r.r_reason_desc
)
SELECT
    ragg.r_reason_id,
    ragg.r_reason_desc,
    'AvgReturnAmt' AS metric_name,
    ragg.avg_return_amt AS metric_value
FROM reason_agg ragg
WHERE ragg.avg_return_amt > 15

UNION ALL

SELECT
    r.r_reason_id,
    r.r_reason_desc,
    'HighAcctCreditCnt' AS metric_name,
    CAST(COUNT(*) AS double) AS metric_value
FROM tpcds.web_returns wr
JOIN tpcds.reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE wr.wr_account_credit > 30
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_order_number = wr.wr_order_number
          AND wr2.wr_return_amt > wr.wr_return_amt
      )
GROUP BY r.r_reason_id, r.r_reason_desc
ORDER BY metric_value DESC, r_reason_id
LIMIT 100
