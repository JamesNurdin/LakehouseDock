WITH base AS (
    SELECT
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        r.r_reason_desc,
        td.t_hour,
        p.p_channel_radio,
        cc.cc_employees,
        wp.wp_image_count,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        cs.cs_quantity,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Single' END AS order_type
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
                      AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                      AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
                        AND wr.wr_web_page_sk = wp.wp_web_page_sk
                        AND wr.wr_reason_sk = r.r_reason_sk
                        AND wr.wr_item_sk = ws.ws_item_sk
                        AND wr.wr_order_number = ws.ws_order_number
    WHERE p.p_channel_radio = 'N'
      AND cc.cc_employees > 1000000
      AND wp.wp_image_count >= 3
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    cc_name,
    cp_department,
    sm_type,
    r_reason_desc,
    SUM(cs_net_profit) AS total_catalog_profit,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(wr_net_loss) AS total_web_return_loss,
    COUNT(*) AS txn_count,
    CASE WHEN SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(sr_net_loss) - SUM(wr_net_loss) > 0
         THEN 'Overall Profit' ELSE 'Overall Loss' END AS overall_status
FROM base
GROUP BY ROLLUP (cc_name, cp_department, sm_type, r_reason_desc)
HAVING SUM(cs_net_profit) > 10000
ORDER BY total_catalog_profit DESC
LIMIT 100
