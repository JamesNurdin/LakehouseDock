WITH store_stats AS (
    SELECT
        sr_store_sk AS store_sk,
        AVG(sr_net_loss) AS avg_net_loss_store,
        SUM(sr_return_quantity) AS total_qty_store,
        COUNT(*) AS cnt_store
    FROM store_returns
    WHERE sr_return_time_sk IN (46418, 47480, 37700, 38957, 41617)
      AND sr_return_ship_cost > 0
    GROUP BY sr_store_sk
    HAVING SUM(sr_return_quantity) > 10
)
SELECT
    sr.sr_customer_sk,
    sr.sr_store_sk,
    COUNT(*) AS return_cnt,
    AVG(sr.sr_net_loss) AS avg_net_loss_customer,
    SUM(sr.sr_return_amt) AS total_return_amt,
    ss.avg_net_loss_store,
    AVG(sr.sr_net_loss) / ss.avg_net_loss_store AS loss_ratio,
    RANK() OVER (ORDER BY AVG(sr.sr_net_loss) DESC) AS loss_rank
FROM store_returns sr
JOIN store_stats ss
    ON sr.sr_store_sk = ss.store_sk
WHERE sr.sr_return_time_sk IN (46418, 47480, 37700, 38957, 41617)
  AND sr.sr_net_loss > 100
GROUP BY sr.sr_customer_sk, sr.sr_store_sk, ss.avg_net_loss_store
HAVING COUNT(*) >= 5
ORDER BY loss_ratio DESC
LIMIT 10
