WITH store_agg AS (
   SELECT ss.ss_item_id AS i_item_id,
          SUM(ss.ss_quantity) AS store_quantity
   FROM store_sales ss
   GROUP BY ss.ss_item_id
),
web_agg AS (
   SELECT ws.ws_item_id AS i_item_id,
          SUM(ws.ws_quantity) AS web_quantity
   FROM web_sales ws
   GROUP BY ws.ws_item_id
),
item_sales AS (
   SELECT i.i_item_id,
          i.i_category,
          COALESCE(sa.store_quantity, 0) AS store_quantity,
          COALESCE(wa.web_quantity, 0) AS web_quantity,
          COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity
   FROM items i
   LEFT JOIN store_agg sa ON sa.i_item_id = i.i_item_id
   LEFT JOIN web_agg wa ON wa.i_item_id = i.i_item_id
)
SELECT isales.i_category,
       SUM(isales.store_quantity) AS total_store_quantity,
       SUM(isales.web_quantity) AS total_web_quantity,
       SUM(isales.total_quantity) AS total_quantity,
       AVG(pr.pr_sentiment) AS avg_sentiment,
       COUNT(pr.pr_review_id) AS review_count
FROM item_sales isales
LEFT JOIN product_reviews pr ON pr.pr_item_id = isales.i_item_id
GROUP BY isales.i_category
ORDER BY total_quantity DESC
LIMIT 10
