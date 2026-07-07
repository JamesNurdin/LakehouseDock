WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
    LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
),
item_reviews AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT isales.i_category,
       isales.i_category_id,
       SUM(isales.total_quantity) AS total_quantity_sold,
       AVG(irev.avg_sentiment) AS avg_review_sentiment,
       SUM(irev.review_count) AS total_reviews
FROM item_sales isales
LEFT JOIN item_reviews irev ON isales.i_item_id = irev.i_item_id
GROUP BY isales.i_category, isales.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
