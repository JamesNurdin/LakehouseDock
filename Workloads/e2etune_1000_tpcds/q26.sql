WITH reason_returns AS (
    SELECT
        r.r_reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) FILTER (WHERE wr.wr_return_quantity > 1) AS total_return_amt_multi_qty
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 500
      AND r.r_reason_desc IN ('Package was damaged', 'Parts missing')
    GROUP BY r.r_reason_desc
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    rr.r_reason_desc,
    rr.total_return_amt,
    rr.total_net_loss,
    rr.avg_return_amt,
    rr.return_cnt,
    rr.total_return_amt_multi_qty,
    RANK() OVER (ORDER BY rr.total_net_loss DESC) AS net_loss_rank,
    ROUND(rr.total_net_loss / NULLIF(rr.total_return_amt, 0), 4) AS loss_to_return_ratio
FROM reason_returns rr
ORDER BY rr.total_net_loss DESC
LIMIT 10
