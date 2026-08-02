SELECT
    wsit.web_state,
    wsit.web_city,
    sm.sm_type,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ws.ws_ext_discount_amt ELSE 0 END) AS total_discount_amount,
    COUNT(DISTINCT CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_order_number END) AS return_order_cnt,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_channel_email = 'Y') AS avg_promo_cost_email
FROM web_sales ws
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh
    ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
FULL OUTER JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN time_dim t_return
    ON wr.wr_returned_time_sk = t_return.t_time_sk
LEFT JOIN web_page wp_ret
    ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
WHERE t_sold.t_meal_time = 'dinner'
  AND wsit.web_state IN ('NY', 'CA', 'TX')
  AND EXISTS (
      SELECT 1
      FROM promotion psub
      WHERE psub.p_promo_sk = ws.ws_promo_sk
        AND psub.p_channel_radio = 'Y'
  )
GROUP BY wsit.web_state, wsit.web_city, sm.sm_type
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
