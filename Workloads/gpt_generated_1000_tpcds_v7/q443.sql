WITH base AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_ship_cost,
        sr.sr_reason_sk,
        td.t_hour,
        td.t_shift
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_return_ship_cost > 100
      AND sr.sr_reason_sk IN (15, 21, 38)
      AND td.t_shift = 'first'
)
SELECT
    base.sr_store_sk,
    base.t_hour,
    base.t_shift,
    COUNT(*) AS cnt_returns,
    SUM(base.sr_return_amt) AS total_return_amt,
    AVG(base.sr_return_tax) AS avg_return_tax,
    MAX(base.sr_return_ship_cost) AS max_ship_cost,
    (
        SELECT AVG(sr3.sr_return_amt)
        FROM store_returns sr3
        WHERE sr3.sr_reason_sk = base.sr_reason_sk
    ) AS avg_return_amt_by_reason
FROM base
GROUP BY
    base.sr_store_sk,
    base.t_hour,
    base.t_shift,
    base.sr_reason_sk
HAVING COUNT(*) > 5
ORDER BY total_return_amt DESC
LIMIT 20
