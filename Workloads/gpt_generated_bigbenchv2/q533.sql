WITH store_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           i.i_price,
           COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
    LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
),
item_reviews AS (
    SELECT pr_item_id,
           COUNT(*) AS review_count,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT isales.i_category,
       isales.i_category_id,
       COUNT(isales.i_item_id) AS item_count,
       SUM(isales.total_quantity) AS total_quantity_sold,
       SUM(COALESCE(irev.review_count, 0)) AS total_review_count,
       AVG(COALESCE(irev.avg_sentiment, 0)) AS avg_sentiment,
       AVG(isales.i_price) AS avg_item_price
FROM item_sales isales
LEFT JOIN item_reviews irev ON isales.i_item_id = irev.pr_item_id
GROUP BY isales.i_category, isales.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
