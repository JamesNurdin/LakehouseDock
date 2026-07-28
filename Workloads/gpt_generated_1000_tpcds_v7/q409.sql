WITH reason_agg AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        SUM(w.wr_return_amt) AS total_return_amt,
        SUM(w.wr_net_loss) AS total_net_loss,
        AVG(w.wr_return_ship_cost) AS avg_ship_cost,
        COUNT(*) AS return_cnt
    FROM tpcds.web_returns w
    JOIN tpcds.reason r
        ON w.wr_reason_sk = r.r_reason_sk
    WHERE w.wr_return_ship_cost > 20
      AND w.wr_return_amt >= 200
      AND w.wr_return_quantity > 0
      AND w.wr_refunded_addr_sk IN (5352658, 5669090, 454321)
      AND r.r_reason_id LIKE 'AAAA%'
    GROUP BY r.r_reason_id, r.r_reason_desc
)
SELECT
    sub.r_desc,
    sub.r_id,
    sub.total_return_amt,
    sub.total_net_loss,
    sub.avg_ship_cost,
    sub.return_cnt,
    sub.avg_net_loss_per_return
FROM (
    SELECT
        r_reason_desc AS r_desc,
        r_reason_id AS r_id,
        total_return_amt,
        total_net_loss,
        avg_ship_cost,
        return_cnt,
        total_net_loss / NULLIF(return_cnt, 0) AS avg_net_loss_per_return
    FROM reason_agg
) sub
WHERE sub.total_return_amt > 5000
  AND sub.avg_ship_cost > 30
  AND sub.return_cnt >= 5
ORDER BY sub.avg_net_loss_per_return DESC
LIMIT 100
