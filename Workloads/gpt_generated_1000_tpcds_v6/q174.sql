WITH catalog_agg AS (
    SELECT
        'catalog' AS channel,
        cr.cr_warehouse_sk AS warehouse_sk,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cr.cr_warehouse_sk
),
web_agg AS (
    SELECT
        'web' AS channel,
        ws.ws_warehouse_sk AS warehouse_sk,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ws.ws_warehouse_sk
)
SELECT channel, warehouse_sk, total_net_loss
FROM catalog_agg
UNION ALL
SELECT channel, warehouse_sk, total_net_loss
FROM web_agg
ORDER BY total_net_loss DESC
LIMIT 100
