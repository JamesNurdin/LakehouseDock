WITH store_ret AS (
   SELECT i.i_brand AS brand,
          CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
          SUM(sr.sr_return_amt) AS amount,
          COUNT(*) AS cnt,
          'store_return' AS source
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   WHERE REGEXP_LIKE(i.i_item_desc, '(?i)deluxe|premium')
     AND i.i_item_id LIKE 'ITEM_%'
     AND t.t_meal_time = 'dinner'
   GROUP BY i.i_brand, i.i_category
),
web_sal AS (
   SELECT i.i_brand AS brand,
          CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
          SUM(ws.ws_net_profit) AS amount,
          COUNT(*) AS cnt,
          'web_sales' AS source
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   WHERE REGEXP_EXTRACT(i.i_product_name, '^([A-Z])', 1) = 'A'
     AND sm.sm_carrier LIKE '%Express%'
     AND t.t_meal_time = 'lunch'
   GROUP BY i.i_brand, i.i_category
)
SELECT brand,
       brand_category,
       source,
       amount,
       cnt
FROM store_ret
UNION ALL
SELECT brand,
       brand_category,
       source,
       amount,
       cnt
FROM web_sal
ORDER BY amount DESC
LIMIT 100
