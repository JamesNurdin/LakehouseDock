WITH filtered_returns AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_reversed_charge,
        sr.sr_reason_sk
    FROM store_returns sr
    WHERE sr.sr_reversed_charge >= 100
      AND sr.sr_reason_sk IN (17, 24, 61)
)
SELECT
    i.i_brand,
    i.i_manager_id,
    COUNT(*) AS return_count,
    SUM(fr.sr_return_amt) AS total_return_amount,
    SUM(fr.sr_net_loss) AS total_net_loss
FROM filtered_returns fr
JOIN item i
    ON fr.sr_item_sk = i.i_item_sk
WHERE i.i_item_id LIKE 'AAAAAAA%'
GROUP BY i.i_brand, i.i_manager_id
ORDER BY total_net_loss DESC
LIMIT 10
