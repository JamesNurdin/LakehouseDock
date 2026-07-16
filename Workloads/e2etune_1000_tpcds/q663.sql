WITH returns_by_time AS (
    SELECT
        wr.wr_returned_time_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        SUM(CASE WHEN wr.wr_fee > 0 THEN 1 ELSE 0 END) AS fee_cnt,
        AVG(wr.wr_return_quantity) AS avg_qty
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
      AND wr.wr_return_quantity > 0
    GROUP BY wr.wr_returned_time_sk
    HAVING COUNT(*) > 5
)
SELECT
    t.t_shift,
    t.t_meal_time,
    t.t_hour,
    r.total_return_amt,
    r.total_tax,
    r.total_net_loss,
    r.return_cnt,
    r.fee_cnt,
    r.avg_qty,
    r.fee_cnt * 100.0 / r.return_cnt AS pct_with_fee,
    CASE
        WHEN r.total_return_amt = 0 THEN 0
        ELSE r.total_net_loss / r.total_return_amt
    END AS net_loss_ratio
FROM returns_by_time r
JOIN time_dim t
  ON r.wr_returned_time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 1 AND 3
  AND t.t_shift IN ('first', 'second')
ORDER BY r.total_return_amt DESC
LIMIT 20
