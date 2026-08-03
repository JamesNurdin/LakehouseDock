WITH online_sales AS (
   SELECT
       i.i_category AS category,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COUNT(*) AS order_count,
       (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_category = i.i_category) AS max_item_price
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE wsite.web_street_type = 'ST'
     AND i.i_category IN (
         SELECT DISTINCT i_sub.i_category
         FROM item i_sub
         WHERE i_sub.i_class_id IN (6, 7)
     )
   GROUP BY i.i_category
   HAVING SUM(ws.ws_ext_sales_price) > 10000
),
store_returns_agg AS (
   SELECT
       i.i_category AS category,
       SUM(sr.sr_return_amt) AS total_returns,
       COUNT(*) AS return_count
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE i.i_category IN (
         SELECT DISTINCT i_sub2.i_category
         FROM item i_sub2
         WHERE i_sub2.i_class_id IN (6, 7)
   )
   GROUP BY i.i_category
   HAVING SUM(sr.sr_return_amt) > 5000
)
SELECT
   category,
   total_sales,
   order_count,
   max_item_price,
   NULL AS total_returns,
   NULL AS return_count
FROM online_sales
UNION ALL
SELECT
   category,
   NULL AS total_sales,
   NULL AS order_count,
   NULL AS max_item_price,
   total_returns,
   return_count
FROM store_returns_agg
ORDER BY category
LIMIT 100
