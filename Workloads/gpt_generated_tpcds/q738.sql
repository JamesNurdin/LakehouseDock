WITH cs_agg AS (
    SELECT
        promotion.p_promo_id,
        ship_mode.sm_ship_mode_id,
        SUM(catalog_sales.cs_net_profit) AS catalog_net_profit,
        SUM(catalog_sales.cs_ext_sales_price) AS catalog_sales_amount,
        COUNT(*) AS catalog_orders
    FROM catalog_sales
    JOIN promotion
        ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    JOIN ship_mode
        ON catalog_sales.cs_ship_mode_sk = ship_mode.sm_ship_mode_sk
    GROUP BY
        promotion.p_promo_id,
        ship_mode.sm_ship_mode_id
),
ws_agg AS (
    SELECT
        promotion.p_promo_id,
        ship_mode.sm_ship_mode_id,
        SUM(web_sales.ws_net_profit) AS web_net_profit,
        SUM(web_sales.ws_ext_sales_price) AS web_sales_amount,
        COUNT(*) AS web_orders
    FROM web_sales
    JOIN promotion
        ON web_sales.ws_promo_sk = promotion.p_promo_sk
    JOIN ship_mode
        ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
    GROUP BY
        promotion.p_promo_id,
        ship_mode.sm_ship_mode_id
),
cr_agg AS (
    SELECT
        promotion.p_promo_id,
        ship_mode.sm_ship_mode_id,
        SUM(catalog_returns.cr_net_loss) AS returns_net_loss,
        SUM(catalog_returns.cr_return_amount) AS returns_amount,
        COUNT(*) AS returns_count
    FROM catalog_returns
    JOIN catalog_sales
        ON catalog_returns.cr_item_sk = catalog_sales.cs_item_sk
       AND catalog_returns.cr_order_number = catalog_sales.cs_order_number
    JOIN promotion
        ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    JOIN ship_mode
        ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
    GROUP BY
        promotion.p_promo_id,
        ship_mode.sm_ship_mode_id
)
SELECT
    COALESCE(cs.p_promo_id, ws.p_promo_id, cr.p_promo_id) AS promo_id,
    COALESCE(cs.sm_ship_mode_id, ws.sm_ship_mode_id, cr.sm_ship_mode_id) AS ship_mode_id,
    COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(cr.returns_net_loss, 0) AS net_profit_after_returns,
    COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) AS total_sales_amount,
    COALESCE(cr.returns_amount, 0) AS total_returns_amount,
    COALESCE(cs.catalog_orders, 0) + COALESCE(ws.web_orders, 0) AS total_orders,
    COALESCE(cr.returns_count, 0) AS total_returns
FROM cs_agg cs
FULL OUTER JOIN ws_agg ws
    ON cs.p_promo_id = ws.p_promo_id
   AND cs.sm_ship_mode_id = ws.sm_ship_mode_id
FULL OUTER JOIN cr_agg cr
    ON COALESCE(cs.p_promo_id, ws.p_promo_id) = cr.p_promo_id
   AND COALESCE(cs.sm_ship_mode_id, ws.sm_ship_mode_id) = cr.sm_ship_mode_id
ORDER BY net_profit_after_returns DESC
LIMIT 10
