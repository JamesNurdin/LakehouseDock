WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk,
             inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    i.i_category,
    i.i_item_id,
    cp.cp_catalog_number,
    cc.cc_name AS call_center_name,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    inv_agg.total_on_hand,
    COUNT(wr.wr_reason_sk) AS return_cnt,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY i.i_category ORDER BY (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_return_amt), 0)) DESC) AS profit_rank_in_category,
    CASE
        WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_return_amt), 0)) > 10000 THEN 'High'
        WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_return_amt), 0)) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_level
FROM catalog_sales cs
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
WHERE i.i_rec_start_date >= DATE '2000-01-01'
  AND p.p_discount_active = 'Y'
  AND i.i_units = 'Each'
  AND cs.cs_quantity > 1
  AND ws.ws_quantity >= 1
  AND w.w_state = 'CA'
GROUP BY
    w.w_warehouse_name,
    i.i_category,
    i.i_item_id,
    cp.cp_catalog_number,
    cc.cc_name,
    inv_agg.total_on_hand
ORDER BY net_profit_after_returns DESC
LIMIT 100
