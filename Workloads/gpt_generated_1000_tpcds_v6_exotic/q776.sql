WITH ws_agg AS (
    SELECT
        ws_bill_customer_sk,
        ws_ship_mode_sk,
        ws_web_site_sk,
        SUM(ws_net_paid_inc_ship) AS total_net_paid,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_bill_customer_sk, ws_ship_mode_sk, ws_web_site_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    wsite.web_name,
    ws_agg.total_net_paid,
    ws_agg.total_profit,
    SUM(sr.sr_net_loss) AS store_net_loss,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ws_agg.total_net_paid DESC) AS rn
FROM store_returns sr
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN ws_agg ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm_ws ON ws_agg.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN ship_mode sm_ws2 ON ws_agg.ws_ship_mode_sk = sm_ws2.sm_ship_mode_sk
JOIN web_site wsite ON ws_agg.ws_web_site_sk = wsite.web_site_sk
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
      AND cr2.cr_order_number <> cr.cr_order_number
)
GROUP BY
    s.s_store_id,
    s.s_store_name,
    wsite.web_name,
    ws_agg.total_net_paid,
    ws_agg.total_profit
HAVING
    SUM(sr.sr_net_loss) > 1000
ORDER BY ws_agg.total_net_paid DESC
LIMIT 100
