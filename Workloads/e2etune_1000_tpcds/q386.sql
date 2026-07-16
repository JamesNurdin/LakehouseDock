WITH catalog_agg AS (
    SELECT
        t.t_hour,
        sm.sm_ship_mode_id,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_net_loss > 0
      AND cd.cd_gender = 'M'
    GROUP BY t.t_hour, sm.sm_ship_mode_id
),
store_agg AS (
    SELECT
        t.t_hour,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_amt) AS store_return_amount,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_net_loss > 0
      AND cd.cd_gender = 'F'
    GROUP BY t.t_hour
),
web_sales_agg AS (
    SELECT
        t.t_hour,
        sm.sm_ship_mode_id,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_net_profit IS NOT NULL
    GROUP BY t.t_hour, sm.sm_ship_mode_id
)
SELECT
    ca.t_hour,
    ca.sm_ship_mode_id,
    ca.catalog_net_loss,
    COALESCE(sa.store_net_loss, 0) AS store_net_loss,
    ws.web_net_profit,
    (ca.catalog_net_loss + COALESCE(sa.store_net_loss, 0) - ws.web_net_profit) AS net_loss_minus_profit,
    ca.catalog_return_cnt,
    COALESCE(sa.store_return_cnt, 0) AS store_return_cnt,
    ws.web_sales_cnt
FROM catalog_agg ca
LEFT JOIN store_agg sa ON ca.t_hour = sa.t_hour
LEFT JOIN web_sales_agg ws ON ca.t_hour = ws.t_hour AND ca.sm_ship_mode_id = ws.sm_ship_mode_id
WHERE (ca.catalog_net_loss + COALESCE(sa.store_net_loss, 0)) > 10000
ORDER BY net_loss_minus_profit DESC
LIMIT 100
