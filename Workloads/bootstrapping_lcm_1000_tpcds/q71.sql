SELECT
  s.s_store_id,
  s.s_city,
  d_closed.d_date AS store_close_date,
  COUNT(DISTINCT ws.ws_order_number) AS orders_on_close_date,
  SUM(ws.ws_net_profit) AS total_net_profit,
  SUM(ws.ws_ext_sales_price) AS total_sales_amount,
  SUM(CASE WHEN d_ship.d_date_sk = d_closed.d_date_sk THEN ws.ws_ext_ship_cost ELSE 0 END) AS total_ship_cost_on_close_date,
  SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
  SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_quantity,
  COUNT(DISTINCT p.p_promo_id) AS promotions_started_on_close_date,
  MAX(p.p_discount_active) AS promotion_discount_active_flag
FROM store s
JOIN date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_closed.d_date_sk
LEFT JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
  AND p.p_start_date_sk = d_closed.d_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_closed.d_date_sk
GROUP BY
  s.s_store_id,
  s.s_city,
  d_closed.d_date
ORDER BY total_net_profit DESC
LIMIT 100
