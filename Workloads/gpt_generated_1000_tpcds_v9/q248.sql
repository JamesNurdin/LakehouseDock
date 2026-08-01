SELECT
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    cc.cc_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_orders,
    SUM(ss.ss_net_paid) AS store_sales_net_paid,
    SUM(ss.ss_net_profit) AS store_sales_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_orders,
    SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
    SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
    SUM(ws.ws_net_paid) AS web_sales_net_paid,
    SUM(ws.ws_net_profit) AS web_sales_net_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_returns_net_loss,
    COALESCE(SUM(wr.wr_net_loss), 0) AS web_returns_net_loss
FROM
    item i
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    cc.cc_state = 'CA'
    AND i.i_category = 'Electronics'
    AND p.p_discount_active = 'N'
    AND ws.ws_quantity > 2
    AND ss.ss_quantity BETWEEN 1 AND 5
    AND cc.cc_rec_start_date >= DATE '2001-01-01'
    AND NOT EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    cc.cc_name
ORDER BY
    store_sales_net_paid DESC
LIMIT 100
