SELECT
  d_sales.d_year AS year,
  d_sales.d_moy AS month,
  i.i_category AS category,
  sm.sm_type AS ship_mode,
  SUM(ws.ws_net_profit) AS total_sales_net_profit,
  SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss,
  SUM(ws.ws_quantity) AS total_quantity_sold,
  SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned,
  SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
  COUNT(DISTINCT p.p_promo_id) AS distinct_promotions,
  (SUM(COALESCE(wr.wr_return_quantity, 0)) / NULLIF(SUM(ws.ws_quantity), 0)) AS return_rate,
  (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_profit_after_returns
FROM web_sales ws
JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = ws.ws_item_sk
WHERE d_sales.d_year = 2001
GROUP BY d_sales.d_year, d_sales.d_moy, i.i_category, sm.sm_type
ORDER BY d_sales.d_year, d_sales.d_moy, i.i_category, sm.sm_type
