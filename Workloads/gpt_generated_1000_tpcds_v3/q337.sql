WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        w.w_warehouse_id,
        w.w_state,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_cs
        ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_promo_sk = p.p_promo_sk
       AND ws.ws_bill_cdemo_sk = cd_cs.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE cs.cs_quantity > 5
      AND ws.ws_quantity > 2
      AND p.p_discount_active = 'Y'
      AND w.w_warehouse_sq_ft > 10000
      AND wsite.web_gmt_offset BETWEEN -5 AND 5
    GROUP BY sm.sm_ship_mode_id, sm.sm_type, w.w_warehouse_id, w.w_state, p.p_promo_name
)
SELECT
    sm_type,
    CASE WHEN AVG(total_net_contrib) > 50000 THEN 'High' ELSE 'Low' END AS profit_category,
    SUM(catalog_net_profit) AS total_catalog_profit,
    SUM(web_net_profit) AS total_web_profit,
    SUM(total_return_loss) AS total_return_loss,
    SUM(total_net_contrib) AS total_net_contrib,
    COUNT(*) AS ship_mode_warehouse_promo_count
FROM (
    SELECT
        sm_type,
        catalog_net_profit,
        web_net_profit,
        total_return_loss,
        (catalog_net_profit + web_net_profit - total_return_loss) AS total_net_contrib
    FROM sales_agg
) sub
GROUP BY sm_type
ORDER BY total_net_contrib DESC
LIMIT 100
