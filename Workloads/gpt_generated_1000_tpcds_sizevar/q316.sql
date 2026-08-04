WITH aggregated_returns AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_reversed_charge > 50.00
      AND sr.sr_store_credit < 20.00
      AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
    GROUP BY r.r_reason_id, r.r_reason_desc
)
SELECT
    r_reason_id,
    r_reason_desc,
    total_return_amt,
    avg_fee,
    return_cnt
FROM aggregated_returns
UNION
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_fee) AS avg_fee,
    COUNT(*) AS return_cnt
FROM store_returns sr
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_fee >= 30.00
  AND sr.sr_return_quantity > 1
  AND r.r_reason_desc LIKE '%product%'
GROUP BY r.r_reason_id, r.r_reason_desc
ORDER BY total_return_amt DESC
LIMIT 100
