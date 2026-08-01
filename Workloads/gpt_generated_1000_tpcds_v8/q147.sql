WITH ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_warehouse_sk,
        wp.wp_web_page_id,
        SUM(ws.ws_net_paid)           AS total_ws_net_paid,
        SUM(ws.ws_net_profit)         AS total_ws_net_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY ws.ws_item_sk, ws.ws_bill_hdemo_sk, ws.ws_warehouse_sk, wp.wp_web_page_id
)
SELECT
    s.s_store_name,
    s.s_state,
    i_ret.i_product_name,
    ws_agg.wp_web_page_id,
    SUM(cs.cs_net_profit)                     AS catalog_net_profit,
    SUM(ws_agg.total_ws_net_profit)           AS web_net_profit,
    SUM(sr.sr_net_loss)                       AS store_return_loss,
    (SUM(cs.cs_net_profit) + SUM(ws_agg.total_ws_net_profit) - SUM(sr.sr_net_loss)) AS total_contribution
FROM store s
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
JOIN item i_ret ON sr.sr_item_sk = i_ret.i_item_sk
JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i_ret.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_cat ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
JOIN item i_cat ON p_cat.p_item_sk = i_cat.i_item_sk
JOIN ws_agg ON ws_agg.ws_item_sk = i_ret.i_item_sk
JOIN warehouse w_web ON ws_agg.ws_warehouse_sk = w_web.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p_check
    WHERE p_check.p_item_sk = i_ret.i_item_sk
      AND p_check.p_discount_active = 'Y'
)
GROUP BY
    s.s_store_name,
    s.s_state,
    i_ret.i_product_name,
    ws_agg.wp_web_page_id
ORDER BY total_contribution DESC
LIMIT 100
