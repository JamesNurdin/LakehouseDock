/* goal: Identify stores with returns due to damage or defect, summarizing return amounts and flagging stores with above‑average returns and any fraud‑related returns. */
WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        s.s_store_name,
        s.s_city,
        td.t_hour
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND s.s_store_name LIKE '%Store%'
)
SELECT
    CONCAT(fr.s_store_name, ' - ', fr.s_city) AS store_location,
    COUNT(*) AS num_returns,
    SUM(fr.sr_return_amt) AS total_return_amount,
    SUM(fr.sr_net_loss) AS total_net_loss,
    AVG(fr.sr_return_amt) AS avg_return_amount,
    CASE
        WHEN SUM(fr.sr_return_amt) > (SELECT AVG(sr_return_amt) FROM filtered_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_amount_category,
    MAX(fr.t_hour) AS latest_return_hour,
    CASE WHEN EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = fr.sr_store_sk
          AND regexp_like(r2.r_reason_desc, '(?i)fraud')
    ) THEN 1 ELSE 0 END AS has_fraud_return
FROM filtered_returns fr
GROUP BY fr.sr_store_sk, fr.s_store_name, fr.s_city
ORDER BY total_return_amount DESC
LIMIT 100
