WITH catalog_sales_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        p.p_promo_id,
        sm.sm_ship_mode_id,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        CAST(NULL AS decimal(7,2)) AS return_loss
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
web_sales_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        p.p_promo_id,
        sm.sm_ship_mode_id,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        CAST(NULL AS decimal(7,2)) AS return_loss
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
returns_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        p.p_promo_id,
        sm.sm_ship_mode_id,
        CAST(NULL AS decimal(7,2)) AS net_paid,
        CAST(NULL AS decimal(7,2)) AS net_profit,
        cr.cr_net_loss AS return_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
)
SELECT
    i_item_id,
    i_product_name,
    p_promo_id,
    sm_ship_mode_id,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(return_loss) AS total_return_loss,
    SUM(COALESCE(net_profit, 0) - COALESCE(return_loss, 0)) AS net_profit_after_returns
FROM (
    SELECT i_item_id, i_product_name, p_promo_id, sm_ship_mode_id, net_paid, net_profit, return_loss FROM catalog_sales_data
    UNION ALL
    SELECT i_item_id, i_product_name, p_promo_id, sm_ship_mode_id, net_paid, net_profit, return_loss FROM web_sales_data
    UNION ALL
    SELECT i_item_id, i_product_name, p_promo_id, sm_ship_mode_id, net_paid, net_profit, return_loss FROM returns_data
) AS combined
GROUP BY i_item_id, i_product_name, p_promo_id, sm_ship_mode_id
ORDER BY total_net_paid DESC
LIMIT 10
