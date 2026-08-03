WITH filtered AS (
    SELECT sr.sr_reason_sk,
           r.r_reason_desc,
           sr.sr_net_loss,
           sr.sr_return_ship_cost
    FROM tpcds.store_returns sr
    JOIN tpcds.reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Did not like the model                                   ...'
      AND sr.sr_return_ship_cost > 100
)
SELECT r_reason_desc,
       COUNT(*) AS return_count,
       SUM(sr_net_loss) AS total_net_loss
FROM filtered
GROUP BY r_reason_desc
ORDER BY total_net_loss DESC
