WITH store_hour_agg AS (
    SELECT
        sr.sr_store_sk,
        t.t_hour,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_fee) AS total_fee
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE
        sr.sr_fee > 20.00               -- fee higher than $20
        AND sr.sr_reason_sk IN (19, 51) -- specific return reasons
        AND t.t_am_pm = 'PM'            -- returns that happened in the PM
    GROUP BY
        sr.sr_store_sk,
        t.t_hour
)
SELECT
    sh.sr_store_sk,
    sh.t_hour,
    sh.total_net_loss,
    sh.total_fee,
    sh.return_cnt,
    (
        SELECT AVG(sr2.sr_fee)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = sh.sr_store_sk
    ) AS avg_fee_per_store,
    CASE
        WHEN sh.return_cnt > 10 THEN 'HIGH_VOLUME'
        ELSE 'LOW_VOLUME'
    END AS volume_category
FROM store_hour_agg sh
WHERE
    sh.return_cnt > 5
    AND sh.sr_store_sk IN (
        SELECT DISTINCT sr_ref.sr_store_sk
        FROM store_returns sr_ref
        WHERE sr_ref.sr_refunded_cash > 0
    )
    AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_store_sk = sh.sr_store_sk
          AND sr3.sr_fee > 30.00
    )
ORDER BY
    sh.total_net_loss DESC,
    sh.sr_store_sk
