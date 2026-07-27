WITH
    agg_returns AS (
        SELECT
            sr_reason_sk,
            COUNT(*) AS return_cnt,
            SUM(sr_return_amt) AS total_return_amt,
            AVG(sr_return_amt) AS avg_return_amt,
            MIN(sr_return_amt) AS min_return_amt,
            MAX(sr_return_amt) AS max_return_amt
        FROM store_returns
        WHERE sr_hdemo_sk IN (527, 3196, 3067)
          AND sr_return_amt BETWEEN 30 AND 400
          AND sr_refunded_cash > 100
          AND sr_store_sk = 5
          AND sr_return_quantity >= 1
          AND sr_return_tax < 50
        GROUP BY sr_reason_sk
    ),
    reason_set AS (
        SELECT r_reason_sk, r_reason_id, r_reason_desc
        FROM reason
        WHERE r_reason_desc LIKE '%color%'
          AND r_reason_id = 'AAAAAAAABAAAAAAA'
        UNION
        SELECT r_reason_sk, r_reason_id, r_reason_desc
        FROM reason
        WHERE r_reason_desc LIKE '%warranty%'
          AND r_reason_id = 'AAAAAAAAMAAAAAAA'
    )
SELECT DISTINCT
    rs.r_reason_desc,
    ar.return_cnt,
    ar.total_return_amt,
    ar.avg_return_amt,
    ar.min_return_amt,
    ar.max_return_amt
FROM agg_returns ar
JOIN reason_set rs
    ON ar.sr_reason_sk = rs.r_reason_sk
ORDER BY ar.total_return_amt DESC
LIMIT 100
