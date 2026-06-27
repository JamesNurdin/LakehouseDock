WITH catalog_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(COALESCE(cr.cr_net_loss, CAST(0 AS decimal(7,2)))) AS total_return_loss,
        COUNT(DISTINCT cs.cs_order_number) AS sales_orders,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    GROUP BY sm.sm_ship_mode_id, cd.cd_gender
),
web_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode,
        cd.cd_gender AS gender,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        CAST(0 AS decimal(7,2)) AS total_return_loss,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders,
        0 AS return_orders
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    GROUP BY sm.sm_ship_mode_id, cd.cd_gender
)
SELECT
    ship_mode,
    gender,
    SUM(total_sales_profit) AS total_sales_profit,
    SUM(total_return_loss) AS total_return_loss,
    SUM(total_sales_profit) - SUM(total_return_loss) AS net_profit_after_returns,
    SUM(sales_orders) AS sales_orders,
    SUM(return_orders) AS return_orders
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
GROUP BY ship_mode, gender
ORDER BY net_profit_after_returns DESC
