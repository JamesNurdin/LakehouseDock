WITH reason_stats AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        AVG(wr.wr_fee) AS avg_fee,
        SUM(wr.wr_return_tax) AS sum_return_tax
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 100
      AND wr.wr_fee BETWEEN 10 AND 200
      AND wr.wr_reversed_charge < 300
    GROUP BY r.r_reason_sk, r.r_reason_desc
)
SELECT
    rs.r_reason_desc,
    rs.cnt_returns,
    rs.sum_return_amt,
    rs.avg_fee,
    rs.sum_return_tax,
    ROW_NUMBER() OVER (ORDER BY rs.sum_return_amt DESC) AS reason_rank,
    (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2 WHERE wr2.wr_return_amt > 0) AS overall_avg_return_amt
FROM reason_stats rs
WHERE EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = rs.r_reason_sk
          AND r2.r_reason_desc LIKE '%price%'
    )
  AND rs.cnt_returns > 5
  AND rs.avg_fee > 20
ORDER BY rs.sum_return_amt DESC
LIMIT 100
