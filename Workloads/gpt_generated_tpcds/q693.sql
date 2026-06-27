WITH catalog_sales_agg AS (
    SELECT
        cs.cs_ship_mode_sk AS ship_mode_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount
    FROM catalog_sales cs
    GROUP BY cs.cs_ship_mode_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_ship_mode_sk AS ship_mode_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount
    FROM web_sales ws
    GROUP BY ws.ws_ship_mode_sk
),
returns_agg AS (
    SELECT
        cr.cr_ship_mode_sk AS ship_mode_sk,
        SUM(cr.cr_net_loss) AS returns_net_loss,
        SUM(cr.cr_return_amount) AS returns_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_ship_mode_sk
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    COALESCE(cs.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(ws.web_net_profit, 0) AS web_net_profit,
    COALESCE(r.returns_net_loss, 0) AS returns_net_loss,
    COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(r.returns_net_loss, 0) AS net_profit_after_returns
FROM ship_mode sm
LEFT JOIN catalog_sales_agg cs
    ON cs.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_sales_agg ws
    ON ws.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns_agg r
    ON r.ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY net_profit_after_returns DESC
