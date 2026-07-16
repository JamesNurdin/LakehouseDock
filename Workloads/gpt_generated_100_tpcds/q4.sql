WITH cs_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        SUM(cs.cs_net_profit) AS total_catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM catalog_sales cs
    GROUP BY cs.cs_ship_mode_sk
),
ws_agg AS (
    SELECT
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_profit) AS total_web_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM web_sales ws
    GROUP BY ws.ws_ship_mode_sk
),
cr_agg AS (
    SELECT
        cr.cr_ship_mode_sk,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_order_count
    FROM catalog_returns cr
    GROUP BY cr.cr_ship_mode_sk
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    COALESCE(cs.total_catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(ws.total_web_net_profit, 0) AS web_net_profit,
    COALESCE(cr.total_return_net_loss, 0) AS return_net_loss,
    COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
    COALESCE(ws.total_web_sales, 0) AS web_sales,
    COALESCE(cr.total_return_amount, 0) AS return_amount,
    COALESCE(cs.catalog_order_count, 0) AS catalog_orders,
    COALESCE(ws.web_order_count, 0) AS web_orders,
    COALESCE(cr.return_order_count, 0) AS return_orders,
    (COALESCE(cs.total_catalog_net_profit, 0) + COALESCE(ws.total_web_net_profit, 0) - COALESCE(cr.total_return_net_loss, 0)) AS net_total_profit
FROM ship_mode sm
LEFT JOIN cs_agg cs
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN ws_agg ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN cr_agg cr
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY sm.sm_ship_mode_id
