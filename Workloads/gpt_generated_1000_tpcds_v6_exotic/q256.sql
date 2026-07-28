WITH store_agg AS (
  SELECT d.d_year AS year,
         p.p_promo_id AS promo_id,
         SUM(ss.ss_net_profit) AS net_profit,
         'store' AS source
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE p.p_channel_email = 'Y'
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, p.p_promo_id
),
web_agg AS (
  SELECT d.d_year AS year,
         p.p_promo_id AS promo_id,
         SUM(ws.ws_net_profit) AS net_profit,
         'web' AS source
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE p.p_channel_email = 'Y'
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, p.p_promo_id
),
combined AS (
  SELECT year, promo_id, net_profit, source FROM store_agg
  UNION ALL
  SELECT year, promo_id, net_profit, source FROM web_agg
)
SELECT DISTINCT year,
       promo_id,
       net_profit,
       source
FROM combined
ORDER BY year, source, promo_id
