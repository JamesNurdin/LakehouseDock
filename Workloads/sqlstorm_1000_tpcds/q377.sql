WITH base_catalog AS (
 SELECT
  cs.cs_sold_date_sk AS date_sk,
  dd.d_date AS sale_date,
  cs.cs_item_sk AS item_sk,
  i.i_product_name AS product_name,
  i.i_category AS category,
  cs.cs_net_paid_inc_ship_tax AS net_paid,
  cs.cs_net_profit AS net_profit,
  cs.cs_quantity AS quantity,
  cs.cs_promo_sk AS promo_sk,
  'catalog' AS channel,
  COALESCE(p.p_promo_name, 'NoPromo') AS promo_name,
  CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'Discounted' ELSE 'FullPrice' END AS discount_type,
  concat(CAST(cs.cs_item_sk AS varchar), '_', CAST(cs.cs_sold_date_sk AS varchar)) AS item_date_key,
  ROW_NUMBER() OVER (PARTITION BY cs.cs_sold_date_sk ORDER BY cs.cs_net_paid_inc_ship_tax DESC) AS daily_rank,
  cc.cc_manager AS call_center_manager
 FROM catalog_sales cs
 JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 WHERE cs.cs_quantity > 0
   AND dd.d_year BETWEEN 1999 AND 2002
),
base_store AS (
 SELECT
  ss.ss_sold_date_sk AS date_sk,
  dd.d_date AS sale_date,
  ss.ss_item_sk AS item_sk,
  i.i_product_name AS product_name,
  i.i_category AS category,
  ss.ss_net_paid_inc_tax AS net_paid,
  ss.ss_net_profit AS net_profit,
  ss.ss_quantity AS quantity,
  ss.ss_promo_sk AS promo_sk,
  'store' AS channel,
  COALESCE(p.p_promo_name, 'NoPromo') AS promo_name,
  CASE WHEN ss.ss_ext_discount_amt > 0 THEN 'Discounted' ELSE 'FullPrice' END AS discount_type,
  concat(CAST(ss.ss_item_sk AS varchar), '_', CAST(ss.ss_sold_date_sk AS varchar)) AS item_date_key,
  ROW_NUMBER() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY ss.ss_net_paid_inc_tax DESC) AS daily_rank,
  CAST(NULL AS varchar) AS call_center_manager
 FROM store_sales ss
 JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 WHERE ss.ss_quantity > 0
   AND dd.d_year BETWEEN 1999 AND 2002
),
base_web AS (
 SELECT
  ws.ws_sold_date_sk AS date_sk,
  dd.d_date AS sale_date,
  ws.ws_item_sk AS item_sk,
  i.i_product_name AS product_name,
  i.i_category AS category,
  ws.ws_net_paid_inc_ship_tax AS net_paid,
  ws.ws_net_profit AS net_profit,
  ws.ws_quantity AS quantity,
  ws.ws_promo_sk AS promo_sk,
  'web' AS channel,
  COALESCE(p.p_promo_name, 'NoPromo') AS promo_name,
  CASE WHEN ws.ws_ext_discount_amt > 0 THEN 'Discounted' ELSE 'FullPrice' END AS discount_type,
  concat(CAST(ws.ws_item_sk AS varchar), '_', CAST(ws.ws_sold_date_sk AS varchar)) AS item_date_key,
  ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_paid_inc_ship_tax DESC) AS daily_rank,
  CAST(NULL AS varchar) AS call_center_manager
 FROM web_sales ws
 JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 WHERE ws.ws_quantity > 0
   AND dd.d_year BETWEEN 1999 AND 2002
),
combined_sales AS (
 SELECT * FROM base_catalog
 UNION ALL
 SELECT * FROM base_store
 UNION ALL
 SELECT * FROM base_web
),
enriched_sales AS (
 SELECT
   cs.*,
   (SELECT AVG(cs2.net_profit) FROM combined_sales cs2 WHERE cs2.item_date_key = cs.item_date_key) AS avg_item_profit,
   (SELECT SUM(cs3.net_profit) FROM combined_sales cs3 WHERE cs3.sale_date = cs.sale_date) AS day_total_profit,
   CASE
      WHEN cs.net_profit > 2 * COALESCE((SELECT AVG(cs4.net_profit) FROM combined_sales cs4 WHERE cs4.item_date_key = cs.item_date_key), 0)
      THEN 'HIGH' ELSE 'NORMAL'
   END AS profit_flag
 FROM combined_sales cs
),
profit_threshold AS (
 SELECT approx_percentile(day_total_profit, 0.75) AS profit_75 FROM enriched_sales
)
SELECT
  es.channel,
  es.sale_date,
  es.category,
  es.promo_name,
  es.discount_type,
  SUM(es.net_paid) AS total_net_paid,
  SUM(es.net_profit) AS total_net_profit,
  AVG(es.net_profit) AS avg_net_profit,
  COUNT(*) AS transaction_count,
  MAX(es.daily_rank) AS max_daily_rank,
  CASE WHEN MAX(CASE WHEN es.profit_flag = 'HIGH' THEN 1 ELSE 0 END) = 1 THEN TRUE ELSE FALSE END AS has_high_profit,
  COUNT(DISTINCT es.item_date_key) AS distinct_items_sold,
  COALESCE(es.call_center_manager, 'N/A') AS call_center_manager
FROM enriched_sales es
CROSS JOIN profit_threshold pt
WHERE es.day_total_profit > pt.profit_75
  AND es.avg_item_profit IS NOT NULL
GROUP BY
  es.channel,
  es.sale_date,
  es.category,
  es.promo_name,
  es.discount_type,
  es.call_center_manager
HAVING SUM(es.net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
