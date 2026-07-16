WITH monthly_reason_stats AS (
    SELECT
        r.r_reason_desc,
        date_trunc('month', date_parse(cast(wr.wr_returned_date_sk AS varchar), '%Y%m%d')) AS month,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_return_quantity) AS total_quantity,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY r.r_reason_desc,
        date_trunc('month', date_parse(cast(wr.wr_returned_date_sk AS varchar), '%Y%m%d'))
    HAVING SUM(wr.wr_return_amt) > 0
)
SELECT
    month,
    r_reason_desc,
    total_return_amount,
    total_return_tax,
    total_quantity,
    avg_net_loss,
    return_cnt,
    RANK() OVER (PARTITION BY month ORDER BY total_return_amount DESC) AS amount_rank,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY avg_net_loss DESC) AS loss_rank
FROM monthly_reason_stats
ORDER BY month, amount_rank
LIMIT 200
