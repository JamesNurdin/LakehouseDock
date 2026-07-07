WITH combined_sales AS (
    SELECT ss.ss_item_id AS i_item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS i_item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    JOIN items i
      ON cs.i_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category
),
item_reviews AS (
    SELECT pr.pr_item_id AS i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i_sales.i_category_id,
       i_sales.i_category,
       SUM(i_sales.total_quantity) AS total_quantity_sold,
       AVG(i_reviews.avg_sentiment) AS avg_sentiment_per_category
FROM item_sales i_sales
JOIN item_reviews i_reviews
  ON i_sales.i_item_id = i_reviews.i_item_id
WHERE i_reviews.avg_sentiment >= 3
GROUP BY i_sales.i_category_id, i_sales.i_category
ORDER BY total_quantity_sold DESC
