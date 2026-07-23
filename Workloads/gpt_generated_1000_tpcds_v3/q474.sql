WITH filtered_promotions AS (
  SELECT DISTINCT p.p_promo_sk,
                  p.p_promo_name,
                  p.p_discount_active
  FROM promotion p
  WHERE REGEXP_LIKE(p.p_promo_name, '[0-9]{2,}')
    AND p.p_channel_event = 'N'
),
catalog_data AS (
  SELECT fp.p_promo_sk,
         fp.p_promo_name,
         sm.sm_code AS ship_mode_code,
         cs.cs_net_profit
  FROM catalog_sales cs
  JOIN filtered_promotions fp ON cs.cs_promo_sk = fp.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code LIKE 'A%'
),
web_data AS (
  SELECT fp.p_promo_sk,
         fp.p_promo_name,
         sm.sm_code AS ship_mode_code,
         ws.ws_net_profit
  FROM web_sales ws
  JOIN filtered_promotions fp ON ws.ws_promo_sk = fp.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code LIKE 'A%'
),
combined AS (
  SELECT p_promo_sk, p_promo_name, ship_mode_code, cs_net_profit AS net_profit
  FROM catalog_data
  UNION ALL
  SELECT p_promo_sk, p_promo_name, ship_mode_code, ws_net_profit AS net_profit
  FROM web_data
)
SELECT
  c.p_promo_name,
  c.ship_mode_code,
  MAX(REGEXP_EXTRACT(c.p_promo_name, '([0-9]+)', 1)) AS promo_code,
  SUM(c.net_profit) AS total_net_profit,
  CASE
    WHEN SUM(c.net_profit) > 100000 THEN 'High'
    WHEN SUM(c.net_profit) > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  CONCAT(c.p_promo_name, '_', c.ship_mode_code) AS promo_ship_label
FROM combined c
GROUP BY c.p_promo_name, c.ship_mode_code
HAVING SUM(c.net_profit) > 20000
ORDER BY total_net_profit DESC
