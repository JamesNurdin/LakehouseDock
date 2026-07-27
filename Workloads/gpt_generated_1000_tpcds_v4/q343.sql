WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_net_loss,
        t.t_hour,
        t.t_time_id,
        t.t_am_pm,
        -- extract the first three letters of the time_id
        regexp_extract(t.t_time_id, '^([A-Z]{3})', 1) AS time_prefix
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE regexp_like(t.t_time_id, '^AAAAAAA[AB]')
      AND t.t_am_pm = 'PM'
      AND substring(t.t_time_id, 1, 5) = 'AAAAA'
)
SELECT
    fr.sr_store_sk,
    fr.t_hour,
    fr.time_prefix,
    CONCAT(fr.time_prefix, '-', CAST(fr.t_hour AS varchar)) AS time_key,
    COUNT(*) AS return_cnt,
    SUM(fr.sr_net_loss) AS total_net_loss,
    AVG(fr.sr_fee) AS avg_fee,
    (
        SELECT MAX(sr2.sr_fee)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = fr.sr_store_sk
    ) AS max_fee_for_store
FROM filtered_returns fr
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr3
    WHERE sr3.sr_store_sk = fr.sr_store_sk
      AND sr3.sr_fee > 70
)
GROUP BY
    fr.sr_store_sk,
    fr.t_hour,
    fr.time_prefix,
    CONCAT(fr.time_prefix, '-', CAST(fr.t_hour AS varchar))
ORDER BY total_net_loss DESC
LIMIT 100
