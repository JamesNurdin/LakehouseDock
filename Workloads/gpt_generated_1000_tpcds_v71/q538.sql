WITH filtered_returns AS (
    SELECT
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_account_credit,
        wr.wr_item_sk,
        wr.wr_return_quantity
    FROM web_returns wr
    WHERE wr.wr_return_amt > 10.00
      AND wr.wr_return_tax BETWEEN 5 AND 30
      AND wr.wr_account_credit < 200
      AND wr.wr_item_sk BETWEEN 100000 AND 300000
      AND wr.wr_return_quantity > 0
),
agg AS (
    SELECT
        wr_reason_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_tax,
        COUNT(*) AS return_count,
        AVG(wr_return_amt) AS average_return_amt,
        MAX(wr_return_amt) AS max_return_amt
    FROM filtered_returns
    GROUP BY wr_reason_sk
    HAVING SUM(wr_return_amt) > 1000
)
SELECT DISTINCT
    r.r_reason_desc,
    a.total_return_amt,
    a.total_tax,
    a.return_count,
    a.average_return_amt,
    a.max_return_amt,
    DENSE_RANK() OVER (ORDER BY a.total_return_amt DESC) AS return_amt_rank,
    (SELECT COUNT(*)
       FROM web_returns wr2
       WHERE wr2.wr_reason_sk = r.r_reason_sk
         AND wr2.wr_return_amt > 500) AS high_amount_return_cnt
FROM filtered_returns fr
JOIN reason r ON fr.wr_reason_sk = r.r_reason_sk
JOIN agg a ON a.wr_reason_sk = r.r_reason_sk
ORDER BY a.total_return_amt DESC
LIMIT 100
