WITH reason_agg AS (
    SELECT
        wr.wr_reason_sk,
        COUNT(*) AS ret_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_qty,
        AVG(wr.wr_account_credit) AS avg_credit
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 10
      AND wr.wr_return_amt > 0
      AND wr.wr_refunded_customer_sk IS NOT NULL
    GROUP BY wr.wr_reason_sk
),
joined AS (
    SELECT
        ra.wr_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        ra.ret_cnt,
        ra.total_return_amt,
        ra.total_qty,
        ra.avg_credit,
        CASE
            WHEN ra.total_return_amt > 5000 THEN 'High'
            ELSE 'Low'
        END AS return_level
    FROM reason_agg ra
    JOIN reason r
        ON ra.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id IN ('AAAAAAAEAAAAAAA', 'AAAAAAAAMAAAAAAA', 'AAAAAAAADBAAAAAA')
      AND r.r_reason_desc NOT LIKE '%color%'
)
SELECT
    j.r_reason_id,
    j.r_reason_desc,
    j.ret_cnt,
    j.total_return_amt,
    j.total_qty,
    j.avg_credit,
    j.return_level,
    SUM(j.total_return_amt) OVER (PARTITION BY j.return_level ORDER BY j.total_return_amt DESC) AS cum_return_amt,
    RANK() OVER (ORDER BY j.total_return_amt DESC) AS amt_rank
FROM joined j
WHERE NOT EXISTS (
    SELECT 1
    FROM reason r_ex
    WHERE r_ex.r_reason_sk = j.wr_reason_sk
      AND r_ex.r_reason_desc LIKE '%color%'
)
ORDER BY cum_return_amt DESC
LIMIT 100
