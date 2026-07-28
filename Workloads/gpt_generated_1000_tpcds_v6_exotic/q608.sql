/* goal: Identify top return loss reasons overall and also capture reasons linked to unusually high return amounts */
WITH aggregated AS (
    SELECT
        r.r_reason_desc,
        SUM(w.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        r.r_reason_id
    FROM web_returns w
    JOIN reason r ON w.wr_reason_sk = r.r_reason_sk
    WHERE w.wr_net_loss > 0
    GROUP BY r.r_reason_desc, r.r_reason_id
),
ranked AS (
    SELECT
        r_reason_desc,
        total_net_loss,
        return_cnt,
        ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank
    FROM aggregated
),
high_value AS (
    SELECT
        r.r_reason_desc,
        SUM(w.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CAST(NULL AS integer) AS loss_rank
    FROM web_returns w
    JOIN reason r ON w.wr_reason_sk = r.r_reason_sk
    WHERE w.wr_return_amt > (SELECT AVG(w2.wr_return_amt) FROM web_returns w2)
      AND r.r_reason_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAADAAAAAAA')
    GROUP BY r.r_reason_desc
)
SELECT r_reason_desc, total_net_loss, return_cnt, loss_rank
FROM ranked
UNION ALL
SELECT r_reason_desc, total_net_loss, return_cnt, loss_rank
FROM high_value
LIMIT 100
