WITH store_data AS (
  SELECT DISTINCT
    p.p_promo_name,
    ss.ss_net_profit
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE ss.ss_net_paid > 100
),
store_agg AS (
  SELECT
    p_promo_name AS promo_name,
    SUM(ss_net_profit) AS profit,
    COUNT(*) AS txns
  FROM store_data
  GROUP BY p_promo_name
),
web_data AS (
  SELECT DISTINCT
    p.p_promo_name,
    ws.ws_net_profit
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_type = 'AIR' AND ws.ws_net_paid > 100
),
web_agg AS (
  SELECT
    p_promo_name AS promo_name,
    SUM(ws_net_profit) AS profit,
    COUNT(*) AS txns
  FROM web_data
  GROUP BY p_promo_name
)
SELECT
  promo_name,
  SUM(profit) AS total_profit,
  SUM(txns) AS total_transactions
FROM (
  SELECT promo_name, profit, txns FROM store_agg
  UNION
  SELECT promo_name, profit, txns FROM web_agg
) u
GROUP BY promo_name
ORDER BY total_profit DESC
LIMIT 10
