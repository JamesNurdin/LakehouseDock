WITH catalog_sales_agg AS (
    SELECT sm.sm_ship_mode_id AS ship_mode_id,
           SUM(cs.cs_net_paid)          AS total_catalog_net_paid,
           SUM(cs.cs_net_profit)        AS total_catalog_net_profit
    FROM   catalog_sales cs
    JOIN   ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
),
web_sales_agg AS (
    SELECT sm.sm_ship_mode_id AS ship_mode_id,
           SUM(ws.ws_net_paid)          AS total_web_net_paid,
           SUM(ws.ws_net_profit)        AS total_web_net_profit
    FROM   web_sales ws
    JOIN   ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
),
catalog_returns_agg AS (
    SELECT sm.sm_ship_mode_id AS ship_mode_id,
           SUM(cr.cr_net_loss)          AS total_return_net_loss,
           SUM(cr.cr_return_amount)     AS total_return_amount
    FROM   catalog_returns cr
    JOIN   ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
)
SELECT COALESCE(cs.ship_mode_id, ws.ship_mode_id, cr.ship_mode_id)                     AS ship_mode_id,
       cs.total_catalog_net_paid,
       cs.total_catalog_net_profit,
       ws.total_web_net_paid,
       ws.total_web_net_profit,
       cr.total_return_net_loss,
       (COALESCE(cs.total_catalog_net_profit, 0) +
        COALESCE(ws.total_web_net_profit, 0) -
        COALESCE(cr.total_return_net_loss, 0))                                          AS net_revenue,
       ROW_NUMBER() OVER (ORDER BY (COALESCE(cs.total_catalog_net_profit, 0) +
                                      COALESCE(ws.total_web_net_profit, 0) -
                                      COALESCE(cr.total_return_net_loss, 0)) DESC) AS revenue_rank
FROM   catalog_sales_agg cs
FULL   OUTER JOIN web_sales_agg ws   ON cs.ship_mode_id = ws.ship_mode_id
FULL   OUTER JOIN catalog_returns_agg cr ON COALESCE(cs.ship_mode_id, ws.ship_mode_id) = cr.ship_mode_id
ORDER BY net_revenue DESC
