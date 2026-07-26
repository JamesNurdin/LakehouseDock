WITH reason_stats AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        CASE 
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High'
            WHEN SUM(cr.cr_net_loss) > 5000 THEN 'Medium'
            ELSE 'Low'
        END AS loss_severity
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
)
SELECT
    r_reason_desc,
    return_count,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    loss_severity,
    DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM reason_stats
ORDER BY loss_rank
LIMIT 10
