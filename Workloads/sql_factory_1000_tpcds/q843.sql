WITH catalog_warehouse AS (
    SELECT
        cr.cr_warehouse_sk AS warehouse_sk,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk
),
web_warehouse AS (
    SELECT
        ws.ws_warehouse_sk AS warehouse_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    GROUP BY ws.ws_warehouse_sk
),
warehouse_combined AS (
    SELECT
        COALESCE(cw.warehouse_sk, ww.warehouse_sk) AS warehouse_sk,
        COALESCE(cw.total_net_loss, 0) AS total_net_loss,
        COALESCE(ww.total_net_profit, 0) AS total_net_profit,
        (COALESCE(ww.total_net_profit, 0) - COALESCE(cw.total_net_loss, 0)) AS net_difference
    FROM catalog_warehouse cw
    FULL OUTER JOIN web_warehouse ww
        ON cw.warehouse_sk = ww.warehouse_sk
)
SELECT
    wc.warehouse_sk,
    wc.total_net_loss,
    wc.total_net_profit,
    wc.net_difference,
    CASE
        WHEN wc.net_difference > 0 THEN 'PROFITABLE'
        ELSE 'LOSS'
    END AS warehouse_status,
    DENSE_RANK() OVER (ORDER BY wc.net_difference DESC) AS profit_rank,
    SUM(wc.net_difference) OVER (ORDER BY wc.net_difference DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_difference
FROM warehouse_combined wc
ORDER BY wc.net_difference DESC
LIMIT 10
