WITH cc_with_hours AS (
    SELECT
        cc.*,
        split(cc.cc_hours, ',') AS hours_array
    FROM call_center cc
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    sm.sm_type,
    cc.cc_name,
    cs.cs_net_profit,
    ws.ws_net_profit,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_profit DESC) AS category_profit_rank,
    hour_part,
    web.web_name
FROM catalog_sales cs
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN cc_with_hours cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
    AND ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
CROSS JOIN UNNEST(cc.hours_array) AS u (hour_part)
WHERE i.i_category_id IN (2, 8)
  AND sm.sm_type = 'EXPRESS'
  AND cc.cc_state = 'CA'
  AND t.t_hour BETWEEN 8 AND 12
ORDER BY category_profit_rank, i.i_item_id
LIMIT 100
