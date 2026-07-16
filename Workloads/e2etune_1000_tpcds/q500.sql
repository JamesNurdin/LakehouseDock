WITH ws_state_counts AS (
    SELECT web_state, COUNT(*) AS site_count
    FROM web_site
    GROUP BY web_state
),
aggregated AS (
    SELECT
        ws.web_state,
        ws.web_city,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN web_site ws
        ON cr.cr_returned_date_sk = ws.web_open_date_sk
    WHERE cr.cr_return_quantity > 0
        AND cr.cr_net_loss > 0
        AND ws.web_state IS NOT NULL
    GROUP BY ws.web_state, ws.web_city
    HAVING SUM(cr.cr_net_loss) > 500
)
SELECT
    a.web_state,
    a.web_city,
    a.distinct_orders,
    a.total_net_loss,
    a.avg_return_amount,
    a.total_return_quantity,
    s.site_count,
    RANK() OVER (PARTITION BY a.web_state ORDER BY a.total_net_loss DESC) AS loss_rank_state
FROM aggregated a
JOIN ws_state_counts s
    ON a.web_state = s.web_state
ORDER BY a.total_net_loss DESC
LIMIT 50
