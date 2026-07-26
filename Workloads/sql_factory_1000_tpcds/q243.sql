WITH ws_state_profit AS (
    SELECT
        ca.ca_state AS state,
        SUM(ws.ws_net_profit) AS total_ws_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
cr_state_loss AS (
    SELECT
        ca.ca_state AS state,
        SUM(cr.cr_net_loss) AS total_cr_loss
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT
    COALESCE(p.state, l.state) AS state,
    COALESCE(p.total_ws_profit, 0) AS total_ws_profit,
    COALESCE(l.total_cr_loss, 0) AS total_cr_loss,
    (COALESCE(p.total_ws_profit, 0) - COALESCE(l.total_cr_loss, 0)) AS net_contribution,
    CASE
        WHEN (COALESCE(p.total_ws_profit, 0) - COALESCE(l.total_cr_loss, 0)) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS contribution_flag,
    DENSE_RANK() OVER (ORDER BY (COALESCE(p.total_ws_profit, 0) - COALESCE(l.total_cr_loss, 0)) DESC) AS net_contribution_rank
FROM ws_state_profit p
FULL OUTER JOIN cr_state_loss l ON p.state = l.state
ORDER BY net_contribution_rank
