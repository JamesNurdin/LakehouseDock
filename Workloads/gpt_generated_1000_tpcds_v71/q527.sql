WITH inv_current AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = (SELECT max(inv_date_sk) FROM inventory)
),
inv_previous AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand AS qty_prev
    FROM inventory
    WHERE inv_date_sk = (SELECT max(inv_date_sk) - 30 FROM inventory)
)
SELECT
    s.s_store_name,
    w.w_warehouse_name,
    p.p_promo_name,
    cc.cc_name AS call_center_name,
    t_ret.t_shift AS return_shift,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(inv_current.inv_quantity_on_hand) AS current_inventory_qty,
    SUM(inv_previous.qty_prev) AS previous_inventory_qty
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN time_dim t_sales ON ws.ws_sold_time_sk = t_sales.t_time_sk
JOIN inv_current ON i.i_item_sk = inv_current.inv_item_sk AND w.w_warehouse_sk = inv_current.inv_warehouse_sk
JOIN inv_previous ON i.i_item_sk = inv_previous.inv_item_sk AND w.w_warehouse_sk = inv_previous.inv_warehouse_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_cat ON cr.cr_returned_time_sk = t_cat.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
GROUP BY
    s.s_store_name,
    w.w_warehouse_name,
    p.p_promo_name,
    cc.cc_name,
    t_ret.t_shift
ORDER BY total_web_profit DESC
LIMIT 100
