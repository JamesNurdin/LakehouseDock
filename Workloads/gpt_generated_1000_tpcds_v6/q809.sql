WITH catalog_data AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'catalog' AS source_type,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM
        catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        p.p_discount_active = 'Y'
        AND cc.cc_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM inventory i
            WHERE i.inv_warehouse_sk = w.w_warehouse_sk
              AND i.inv_quantity_on_hand > 0
        )
    GROUP BY
        w.w_warehouse_name
),
web_data AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'web' AS source_type,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM
        web_sales ws
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        p.p_discount_active = 'Y'
        AND wp.wp_type = 'content'
        AND EXISTS (
            SELECT 1
            FROM inventory i
            WHERE i.inv_warehouse_sk = w.w_warehouse_sk
              AND i.inv_quantity_on_hand > 0
        )
    GROUP BY
        w.w_warehouse_name
)
SELECT
    warehouse_name,
    source_type,
    total_profit,
    order_cnt
FROM catalog_data
UNION ALL
SELECT
    warehouse_name,
    source_type,
    total_profit,
    order_cnt
FROM web_data
ORDER BY total_profit DESC
LIMIT 100
