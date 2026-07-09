WITH store_data AS (
 SELECT d.d_year AS sale_year,
        'store' AS channel,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        i.i_category AS i_category,
        s.s_state AS state,
        p.p_promo_name AS promo_name
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
),
catalog_data AS (
 SELECT d.d_year AS sale_year,
        'catalog' AS channel,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        i.i_category AS i_category,
        NULL AS state,
        p.p_promo_name AS promo_name
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
),
web_data AS (
 SELECT d.d_year AS sale_year,
        'web' AS channel,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        i.i_category AS i_category,
        NULL AS state,
        p.p_promo_name AS promo_name
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
)
SELECT sale_year,
       channel,
       SUM(net_profit) AS total_profit,
       SUM(quantity) AS total_quantity,
       COUNT(DISTINCT i_category) AS distinct_categories,
       COUNT(DISTINCT state) AS distinct_states,
       COUNT(DISTINCT promo_name) AS distinct_promos
FROM (
  SELECT sale_year, channel, net_profit, quantity, i_category, state, promo_name FROM store_data
  UNION ALL
  SELECT sale_year, channel, net_profit, quantity, i_category, state, promo_name FROM catalog_data
  UNION ALL
  SELECT sale_year, channel, net_profit, quantity, i_category, state, promo_name FROM web_data
) AS all_sales
GROUP BY sale_year, channel
ORDER BY sale_year, channel
