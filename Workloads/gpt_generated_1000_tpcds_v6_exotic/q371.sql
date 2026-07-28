WITH
  /* Store channel aggregation */
  store_raw AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_item_id, i.i_product_name
  ),
  store_agg AS (
    SELECT
      'store' AS channel,
      i_item_id,
      i_product_name,
      total_net_profit,
      CASE
        WHEN total_net_profit > 10000 THEN 'high'
        WHEN total_net_profit > 0 THEN 'medium'
        ELSE 'low'
      END AS profit_category,
      RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM store_raw
  ),
  /* Web channel aggregation */
  web_raw AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_country = 'USA'
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_item_id, i.i_product_name
  ),
  web_agg AS (
    SELECT
      'web' AS channel,
      i_item_id,
      i_product_name,
      total_net_profit,
      CASE
        WHEN total_net_profit > 10000 THEN 'high'
        WHEN total_net_profit > 0 THEN 'medium'
        ELSE 'low'
      END AS profit_category,
      RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM web_raw
  )
SELECT
  channel,
  i_item_id,
  i_product_name,
  total_net_profit,
  profit_category,
  profit_rank
FROM store_agg
UNION ALL
SELECT
  channel,
  i_item_id,
  i_product_name,
  total_net_profit,
  profit_category,
  profit_rank
FROM web_agg
ORDER BY total_net_profit DESC
LIMIT 100
