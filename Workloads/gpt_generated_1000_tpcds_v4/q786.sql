WITH reason_stats AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returning_addr_sk IN (3431573, 91422)
      AND cr.cr_refunded_hdemo_sk BETWEEN 600 AND 2000
      AND cr.cr_return_ship_cost > 50
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY r.r_reason_sk, r.r_reason_desc
)
SELECT
    r_reason_sk,
    r_reason_desc,
    total_net_loss,
    avg_return_amount,
    return_cnt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
    CASE
        WHEN total_net_loss > 1000 THEN 'High Loss'
        WHEN total_net_loss > 500 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category
FROM reason_stats
ORDER BY loss_rank
LIMIT 10
