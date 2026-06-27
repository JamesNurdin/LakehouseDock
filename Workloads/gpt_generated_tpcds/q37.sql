WITH catalog_sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        cd.cd_gender,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    GROUP BY sm.sm_ship_mode_id, cd.cd_gender
),
catalog_returns_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        cd.cd_gender,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY sm.sm_ship_mode_id, cd.cd_gender
),
web_sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    GROUP BY sm.sm_ship_mode_id, cd.cd_gender
)
SELECT
    cs.sm_ship_mode_id,
    cs.cd_gender,
    cs.total_catalog_profit,
    cr.total_return_amount,
    cr.total_return_loss,
    (cs.total_catalog_profit - COALESCE(cr.total_return_loss, 0)) AS net_catalog_profit_after_returns,
    ws.total_web_profit,
    ws.web_order_cnt,
    ws.web_quantity
FROM catalog_sales_agg cs
LEFT JOIN catalog_returns_agg cr
    ON cs.sm_ship_mode_id = cr.sm_ship_mode_id
    AND cs.cd_gender = cr.cd_gender
LEFT JOIN web_sales_agg ws
    ON cs.sm_ship_mode_id = ws.sm_ship_mode_id
    AND cs.cd_gender = ws.cd_gender
ORDER BY cs.sm_ship_mode_id, cs.cd_gender
