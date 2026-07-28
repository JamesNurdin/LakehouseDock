WITH catalog_sales_evening AS (
  SELECT
    cs.cs_order_number AS order_number,
    cs.cs_net_paid AS net_paid,
    p.p_promo_id AS promo_id,
    t.t_time_id AS time_id,
    sm.sm_ship_mode_id AS ship_mode_id,
    (SELECT avg(cs2.cs_net_paid) FROM catalog_sales cs2 WHERE cs2.cs_promo_sk = cs.cs_promo_sk) AS avg_promo_net_paid
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE p.p_promo_name = 'Holiday Sale'
    AND t.t_sub_shift = 'evening'
),
web_sales_evening AS (
  SELECT
    ws.ws_order_number AS order_number,
    ws.ws_net_paid AS net_paid,
    p.p_promo_id AS promo_id,
    t.t_time_id AS time_id,
    sm.sm_ship_mode_id AS ship_mode_id,
    (SELECT avg(ws2.ws_net_paid) FROM web_sales ws2 WHERE ws2.ws_promo_sk = ws.ws_promo_sk) AS avg_promo_net_paid
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE p.p_promo_name = 'Holiday Sale'
    AND t.t_sub_shift = 'evening'
)
SELECT
  order_number,
  net_paid,
  promo_id,
  time_id,
  ship_mode_id,
  avg_promo_net_paid
FROM (
  SELECT * FROM catalog_sales_evening
  UNION ALL
  SELECT * FROM web_sales_evening
) combined
ORDER BY net_paid DESC
LIMIT 100
