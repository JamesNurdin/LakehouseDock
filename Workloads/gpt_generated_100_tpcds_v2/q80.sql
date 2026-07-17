SELECT
    i.i_product_name,
    sm.sm_type,
    w.w_warehouse_id,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE p.p_discount_active = 'Y'
  AND w.w_state = 'TN'
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-01-31'
GROUP BY i.i_product_name, sm.sm_type, w.w_warehouse_id
ORDER BY total_profit DESC
LIMIT 10
