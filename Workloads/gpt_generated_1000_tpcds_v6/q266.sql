SELECT
    p.p_promo_id,
    t_cs.t_shift,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_net_paid,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
    (SUM(cs.cs_net_profit)
        - SUM(COALESCE(cr.cr_net_loss, 0))
        - SUM(COALESCE(wr.wr_net_loss, 0))
    ) AS net_profit_adjusted
FROM catalog_sales cs
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_item_sk = cs.cs_item_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr_ex
    WHERE cr_ex.cr_order_number = cs.cs_order_number
      AND cr_ex.cr_return_amount > 0
)
GROUP BY
    p.p_promo_id,
    t_cs.t_shift
ORDER BY net_profit_adjusted DESC
LIMIT 100
