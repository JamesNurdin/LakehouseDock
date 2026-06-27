WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_ship_mode_sk,
        SUM(cs_net_profit) AS total_sales_profit
    FROM catalog_sales
    GROUP BY cs_call_center_sk, cs_ship_mode_sk
),
cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_ship_mode_sk,
        SUM(cr_net_loss) AS total_return_loss
    FROM catalog_returns
    GROUP BY cr_call_center_sk, cr_ship_mode_sk
),
ws_agg AS (
    SELECT
        ws_ship_mode_sk,
        SUM(ws_net_profit) AS total_web_profit
    FROM web_sales
    GROUP BY ws_ship_mode_sk
)
SELECT
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode_type,
    cs.total_sales_profit,
    cr.total_return_loss,
    cs.total_sales_profit - cr.total_return_loss AS net_profit_after_returns,
    ws.total_web_profit
FROM cs_agg cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN cr_agg cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN ws_agg ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
