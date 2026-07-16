WITH store_total AS (
    SELECT sr_store_sk,
           SUM(sr_return_amt) AS total_return_amt,
           SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY sr_store_sk
),
store_daily AS (
    SELECT sr_store_sk,
           sr_returned_date_sk,
           SUM(sr_return_amt) AS daily_return_amt,
           SUM(sr_net_loss) AS daily_net_loss
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY sr_store_sk, sr_returned_date_sk
    HAVING SUM(sr_return_amt) > 1000
)
SELECT
    d.sr_store_sk,
    d.sr_returned_date_sk,
    d.daily_return_amt,
    d.daily_net_loss,
    t.total_return_amt,
    t.total_net_loss,
    d.daily_return_amt / NULLIF(t.total_return_amt, 0) AS return_amt_ratio,
    d.daily_net_loss / NULLIF(t.total_net_loss, 0) AS net_loss_ratio,
    RANK() OVER (PARTITION BY d.sr_store_sk ORDER BY d.daily_net_loss DESC) AS daily_net_loss_rank
FROM store_daily d
JOIN store_total t
    ON d.sr_store_sk = t.sr_store_sk
ORDER BY d.sr_store_sk, daily_net_loss_rank
LIMIT 50
