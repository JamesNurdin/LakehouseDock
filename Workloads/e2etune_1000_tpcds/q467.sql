WITH cs_agg AS (
  SELECT
    cs.cs_ship_mode_sk AS ship_mode_sk,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_ext_discount_amt) AS catalog_total_discount
  FROM catalog_sales cs
  WHERE cs.cs_coupon_amt > 0
    AND cs.cs_net_paid_inc_tax > 1000
    AND cs.cs_promo_sk IN (1023, 1057)
  GROUP BY cs.cs_ship_mode_sk
),
ws_agg AS (
  SELECT
    ws.ws_ship_mode_sk AS ship_mode_sk,
    ws.ws_web_site_sk AS web_site_sk,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(ws.ws_ext_discount_amt) AS web_avg_discount
  FROM web_sales ws
  WHERE ws.ws_coupon_amt > 0
    AND ws.ws_net_paid_inc_tax > 1000
    AND ws.ws_promo_sk IN (1023, 1057)
  GROUP BY ws.ws_ship_mode_sk, ws.ws_web_site_sk
)
SELECT
  sm.sm_type AS ship_mode,
  wsit.web_name AS website,
  cs_agg.catalog_net_profit,
  ws_agg.web_net_profit,
  (cs_agg.catalog_net_profit + ws_agg.web_net_profit) AS total_net_profit,
  cs_agg.catalog_total_discount,
  ws_agg.web_avg_discount,
  cs_agg.catalog_order_cnt,
  ws_agg.web_order_cnt,
  (cs_agg.catalog_order_cnt + ws_agg.web_order_cnt) AS total_orders,
  RANK() OVER (PARTITION BY wsit.web_name ORDER BY (cs_agg.catalog_net_profit + ws_agg.web_net_profit) DESC) AS profit_rank
FROM cs_agg
JOIN ship_mode sm ON cs_agg.ship_mode_sk = sm.sm_ship_mode_sk
JOIN ws_agg ON ws_agg.ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsit ON ws_agg.web_site_sk = wsit.web_site_sk
WHERE (cs_agg.catalog_net_profit + ws_agg.web_net_profit) > 5000
ORDER BY wsit.web_name, total_net_profit DESC
LIMIT 200
