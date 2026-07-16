WITH reason_totals AS (
    SELECT
        sr.sr_store_sk,
        r.r_reason_desc,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY sr.sr_store_sk, r.r_reason_desc
),
ranked_reasons AS (
    SELECT
        sr_store_sk,
        r_reason_desc,
        total_return_amount,
        RANK() OVER (PARTITION BY sr_store_sk ORDER BY total_return_amount DESC) AS reason_rank
    FROM reason_totals
)
SELECT
    sr_store_sk,
    r_reason_desc,
    total_return_amount,
    reason_rank
FROM ranked_reasons
WHERE reason_rank <= 3
ORDER BY sr_store_sk, reason_rank
