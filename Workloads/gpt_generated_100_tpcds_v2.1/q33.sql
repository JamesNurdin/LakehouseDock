WITH base_data AS (
  SELECT
    t.t_time_sk,
    t.t_hour,
    t.t_minute,
    sr.sr_ticket_number,
    sr.sr_net_loss,
    cr.cr_net_loss,
    wr.wr_net_loss,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    sm.sm_type AS catalog_ship_mode_type,
    sm2.sm_type AS web_ship_mode_type,
    p.p_promo_name,
    p.p_channel_event,
    s.s_city,
    s.s_state,
    s.s_zip,
    t2.t_meal_time
  FROM time_dim t
  INNER JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
  INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
  INNER JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
  INNER JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  INNER JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
  INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  INNER JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
  LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
  INNER JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
)
SELECT
  t_hour,
  t_minute,
  s_city,
  s_state,
  catalog_ship_mode_type,
  web_ship_mode_type,
  p_promo_name,
  COUNT(DISTINCT sr_ticket_number) AS store_return_count,
  SUM(sr_net_loss) AS total_store_net_loss,
  SUM(cr_net_loss) AS total_catalog_net_loss,
  SUM(wr_net_loss) AS total_web_return_net_loss,
  SUM(ws_net_profit) AS total_web_sales_profit,
  AVG(ws_ext_discount_amt) AS avg_web_discount,
  COUNT(DISTINCT p_promo_name) AS promo_count
FROM base_data
WHERE s_city IN ('Fairfield', 'Buena Vista')
  AND p_channel_event = 'N'
GROUP BY
  t_hour,
  t_minute,
  s_city,
  s_state,
  catalog_ship_mode_type,
  web_ship_mode_type,
  p_promo_name
ORDER BY total_store_net_loss DESC
LIMIT 100
