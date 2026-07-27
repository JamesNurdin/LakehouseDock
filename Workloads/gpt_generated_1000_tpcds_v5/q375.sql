WITH cs_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    GROUP BY
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk
)
SELECT
    cc.cc_name,
    wh_cat.w_warehouse_name,
    sm_cat.sm_type,
    SUM(cs.total_net_paid) AS catalog_sales_net,
    SUM(cr.cr_net_loss) AS catalog_returns_loss,
    SUM(ws.ws_net_paid_inc_tax) AS web_sales_net,
    SUM(wr.wr_net_loss) AS web_returns_loss
FROM cs_agg cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cat
    ON cs.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
JOIN warehouse wh_cat
    ON cs.cs_warehouse_sk = wh_cat.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_ship_mode_sk = sm_cat.sm_ship_mode_sk
   AND cr.cr_warehouse_sk = wh_cat.w_warehouse_sk
JOIN ship_mode sm_ret
    ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN warehouse wh_ret
    ON cr.cr_warehouse_sk = wh_ret.w_warehouse_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = wh_ret.w_warehouse_sk
JOIN ship_mode sm_web
    ON sm_web.sm_ship_mode_sk = sm_cat.sm_ship_mode_sk
JOIN warehouse wh_web
    ON wh_web.w_warehouse_sk = wh_cat.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = wh_web.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
GROUP BY
    cc.cc_name,
    wh_cat.w_warehouse_name,
    sm_cat.sm_type
ORDER BY catalog_sales_net DESC
LIMIT 100
