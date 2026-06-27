WITH catalog_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        cp.cp_department AS catalog_department,
        SUM(cs.cs_net_profit) AS total_catalog_net_profit,
        COALESCE(SUM(cr.cr_refunded_cash), 0) AS total_refunded_cash,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY
        cc.cc_name,
        sm.sm_type,
        cp.cp_department
),
web_agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_web_net_profit,
        SUM(ws.ws_quantity) AS total_web_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        sm.sm_type
)
SELECT
    ca.call_center_name,
    ca.ship_mode_type,
    ca.catalog_department,
    ca.total_catalog_net_profit,
    ca.total_refunded_cash,
    ca.total_catalog_net_profit - ca.total_refunded_cash AS net_profit_after_refunds,
    ca.total_quantity_sold,
    ca.distinct_orders,
    wa.total_web_net_profit,
    wa.total_web_quantity_sold,
    wa.distinct_web_orders
FROM catalog_agg ca
LEFT JOIN web_agg wa
    ON ca.ship_mode_type = wa.ship_mode_type
ORDER BY ca.total_catalog_net_profit - ca.total_refunded_cash DESC
LIMIT 20
