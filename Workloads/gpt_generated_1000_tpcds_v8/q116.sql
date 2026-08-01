-- Goal: Compare hourly sales performance of store vs web channels for morning hours (8‑12), showing total sales, profit, pricing type, profit category, and rank per channel.
WITH filtered_time AS (
  SELECT t_time_sk, t_hour
  FROM time_dim
  WHERE t_hour BETWEEN 8 AND 12
),

store_agg AS (
  SELECT
    ft.t_hour AS hour,
    'store' AS sales_channel,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_ext_discount_amt) > 0 THEN 'Discounted' ELSE 'Full Price' END AS pricing_type
  FROM filtered_time ft
  JOIN store_sales ss ON ss.ss_sold_time_sk = ft.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  GROUP BY ft.t_hour
),

web_agg AS (
  SELECT
    ft.t_hour AS hour,
    'web' AS sales_channel,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_ext_discount_amt) > 0 THEN 'Discounted' ELSE 'Full Price' END AS pricing_type
  FROM filtered_time ft
  JOIN web_sales ws ON ws.ws_sold_time_sk = ft.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY ft.t_hour
)

SELECT
  sales_channel,
  hour,
  total_sales,
  total_profit,
  pricing_type,
  CASE WHEN total_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
  ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_sales DESC) AS sales_rank
FROM (
  SELECT hour, sales_channel, total_sales, total_profit, pricing_type FROM store_agg
  UNION ALL
  SELECT hour, sales_channel, total_sales, total_profit, pricing_type FROM web_agg
) AS combined
ORDER BY sales_channel, sales_rank
LIMIT 100
