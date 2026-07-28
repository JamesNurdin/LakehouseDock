WITH per_page_warehouse AS (
    SELECT
        cp.cp_catalog_page_id,
        w.w_warehouse_id,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        AVG(cs.cs_net_paid_inc_ship) AS avg_catalog_paid,
        AVG(ws.ws_net_paid_inc_ship) AS avg_web_paid
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_catalog_number IN (7, 10, 17)
      AND w.w_country = 'United States'
    GROUP BY cp.cp_catalog_page_id, w.w_warehouse_id
)
SELECT
    cpw.cp_catalog_page_id,
    cpw.w_warehouse_id,
    cpw.catalog_profit,
    cpw.web_profit,
    cpw.catalog_orders,
    cpw.web_orders,
    (cpw.catalog_profit + cpw.web_profit) AS total_profit,
    (cpw.catalog_orders + cpw.web_orders) AS total_orders,
    (cpw.catalog_profit + cpw.web_profit) / NULLIF(cpw.catalog_orders + cpw.web_orders, 0) AS profit_per_order
FROM per_page_warehouse cpw
WHERE (cpw.catalog_profit + cpw.web_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
