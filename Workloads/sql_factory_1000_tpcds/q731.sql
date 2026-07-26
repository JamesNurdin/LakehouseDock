WITH reason_agg AS (
    SELECT
        r.r_reason_desc,
        ca.ca_state,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS total_returns
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    GROUP BY r.r_reason_desc, ca.ca_state
)
SELECT
    r_reason_desc,
    ca_state,
    total_net_loss,
    total_return_amount,
    avg_return_qty,
    total_returns,
    DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY total_net_loss DESC) AS state_reason_rank,
    CASE
        WHEN total_net_loss > 5000 THEN 'Critical'
        WHEN total_net_loss BETWEEN 1000 AND 5000 THEN 'Moderate'
        ELSE 'Low'
    END AS loss_severity
FROM reason_agg
ORDER BY ca_state, state_reason_rank
LIMIT 15
