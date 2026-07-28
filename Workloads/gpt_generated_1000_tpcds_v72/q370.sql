WITH high_credit_hdemo AS (
    SELECT DISTINCT sr_hdemo_sk
    FROM store_returns
    WHERE sr_store_credit > 1000
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_loss,
    COUNT(*) AS return_cnt
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%price%'
  AND sr.sr_return_quantity > 10
  AND EXISTS (SELECT 1 FROM high_credit_hdemo h WHERE h.sr_hdemo_sk = sr.sr_hdemo_sk)
GROUP BY r.r_reason_id, r.r_reason_desc

UNION ALL

SELECT
    r.r_reason_id,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_loss,
    COUNT(*) AS return_cnt
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%damage%'
  AND sr.sr_return_quantity <= 10
  AND sr.sr_hdemo_sk IN (SELECT sr_hdemo_sk FROM high_credit_hdemo)
GROUP BY r.r_reason_id, r.r_reason_desc

ORDER BY total_loss DESC
LIMIT 100
