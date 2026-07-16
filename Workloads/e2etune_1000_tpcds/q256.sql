WITH
store_sales_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        COUNT(*) AS store_sales_cnt,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_net_paid) AS store_net_paid
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id, p.p_promo_name
),
store_returns_agg AS (
    SELECT
        p.p_promo_id,
        COUNT(*) AS store_returns_cnt,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
),
web_sales_agg AS (
    SELECT
        p.p_promo_id,
        sm.sm_ship_mode_id,
        COUNT(*) AS web_sales_cnt,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS web_net_paid_inc_tax
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY p.p_promo_id, sm.sm_ship_mode_id
),
catalog_returns_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        COUNT(*) AS catalog_returns_cnt,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_tax > 10.0
    GROUP BY sm.sm_ship_mode_id, w.w_warehouse_name
)
SELECT
    ss.p_promo_id,
    ss.p_promo_name,
    ss.store_sales_cnt,
    ss.store_net_profit,
    ss.store_net_paid,
    COALESCE(sr.store_returns_cnt, 0) AS store_returns_cnt,
    COALESCE(sr.store_net_loss, 0) AS store_net_loss,
    ws.sm_ship_mode_id,
    ws.web_sales_cnt,
    ws.web_net_profit,
    ws.web_net_paid_inc_tax,
    cr.w_warehouse_name,
    COALESCE(cr.catalog_returns_cnt, 0) AS catalog_returns_cnt,
    COALESCE(cr.catalog_net_loss, 0) AS catalog_net_loss,
    (ss.store_net_profit + ws.web_net_profit) - (COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0)) AS net_contribution
FROM store_sales_agg ss
LEFT JOIN store_returns_agg sr ON ss.p_promo_id = sr.p_promo_id
LEFT JOIN web_sales_agg ws ON ss.p_promo_id = ws.p_promo_id
LEFT JOIN catalog_returns_agg cr ON ws.sm_ship_mode_id = cr.sm_ship_mode_id
WHERE ss.store_net_profit > 0
  AND (ss.store_net_profit + ws.web_net_profit) - (COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0)) > 0
ORDER BY net_contribution DESC
LIMIT 50
