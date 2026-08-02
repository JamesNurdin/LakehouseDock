WITH cat_sales AS (
  SELECT
    i.i_category AS category,
    i.i_item_desc AS item_desc,
    p.p_promo_name AS promo_name,
    sm.sm_type AS ship_mode,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_quantity) AS total_quantity
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE regexp_like(i.i_item_desc, '(?i)eco|green')
    AND p.p_promo_name LIKE '%Discount%'
    AND substring(p.p_promo_name, 1, 3) = 'Eco'
  GROUP BY i.i_category, i.i_item_desc, p.p_promo_name, sm.sm_type
),
web_sales_cte AS (
  SELECT
    i.i_category AS category,
    i.i_item_desc AS item_desc,
    p.p_promo_name AS promo_name,
    sm.sm_type AS ship_mode,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE regexp_like(i.i_item_desc, '(?i)eco|green')
    AND p.p_promo_name LIKE '%Discount%'
    AND substring(p.p_promo_name, 1, 3) = 'Eco'
  GROUP BY i.i_category, i.i_item_desc, p.p_promo_name, sm.sm_type
),
combined AS (
  SELECT category, item_desc, promo_name, ship_mode, total_profit, total_quantity FROM cat_sales
  UNION ALL
  SELECT category, item_desc, promo_name, ship_mode, total_profit, total_quantity FROM web_sales_cte
),
max_total_profit AS (
  SELECT MAX(item_profit) AS max_profit FROM (
    SELECT SUM(cs.cs_net_profit) AS item_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)eco|green')
    GROUP BY i.i_item_id
  ) t
)
SELECT
  category,
  promo_name,
  ship_mode,
  SUM(total_profit) AS profit,
  SUM(total_quantity) AS quantity,
  CONCAT(category, ' - ', promo_name) AS cat_promo,
  regexp_extract(promo_name, '^([A-Za-z]+)', 1) AS promo_prefix
FROM combined
WHERE promo_name IN (
  SELECT p2.p_promo_name
  FROM promotion p2
  WHERE p2.p_discount_active = 'Y'
)
GROUP BY ROLLUP (category, promo_name, ship_mode)
HAVING SUM(total_profit) > (SELECT max_profit FROM max_total_profit)
ORDER BY profit DESC
LIMIT 100
