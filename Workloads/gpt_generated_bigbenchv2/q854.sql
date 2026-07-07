WITH sales AS (
    SELECT ss_item_id AS i_item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS i_item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT i_item_id, SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY i_item_id
),
review_agg AS (
    SELECT pr_item_id AS i_item_id,
           COUNT(pr_review_id) AS review_count,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       sa.total_quantity,
       ra.review_count,
       ra.avg_sentiment
FROM sales_agg sa
JOIN items i ON sa.i_item_id = i.i_item_id
JOIN review_agg ra ON i.i_item_id = ra.i_item_id
WHERE sa.total_quantity > 100
  AND ra.review_count >= 10
ORDER BY sa.total_quantity DESC
LIMIT 5
