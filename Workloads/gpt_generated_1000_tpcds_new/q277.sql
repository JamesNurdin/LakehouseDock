WITH catalog_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
web_sample AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
),
catalog_sub AS (
    SELECT
        COALESCE(cs.cs_order_number, cr.cr_order_number) AS order_number,
        COALESCE(cr.cr_net_loss, cs.cs_net_profit) AS net_loss
    FROM catalog_sample cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
),
web_sub AS (
    SELECT
        COALESCE(ws.ws_order_number, wr.wr_order_number) AS order_number,
        COALESCE(wr.wr_net_loss, ws.ws_net_profit) AS net_loss
    FROM web_sample ws
    FULL OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
)
SELECT *
FROM catalog_sub
INTERSECT
SELECT *
FROM web_sub
ORDER BY net_loss DESC, order_number
LIMIT 100
