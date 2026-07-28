WITH filtered_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    p.p_promo_id,
    p.p_promo_name
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2000
    AND sm.sm_carrier LIKE 'U%'
    AND regexp_like(p.p_promo_name, '\\d{2}')
    AND NOT EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_order_number = ws.ws_order_number
    )
)
SELECT
  sm_ship_mode_id,
  p_promo_name,
  CONCAT(p_promo_id, '-', sm_ship_mode_id) AS promo_ship_key,
  SUBSTRING(p_promo_name, 1, 5) AS promo_name_prefix,
  SUM(ws_net_profit) AS total_net_profit,
  COUNT(*) AS order_count
FROM filtered_sales
GROUP BY
  sm_ship_mode_id,
  p_promo_name,
  p_promo_id,
  SUBSTRING(p_promo_name, 1, 5),
  CONCAT(p_promo_id, '-', sm_ship_mode_id)
ORDER BY total_net_profit DESC
LIMIT 100
