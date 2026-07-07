WITH sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           i.i_price,
           COALESCE(SUM(s.quantity), 0) AS total_quantity,
           COALESCE(SUM(s.quantity * i.i_price), 0) AS total_revenue
    FROM items i
    LEFT JOIN sales s ON s.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category, i.i_price
),
item_reviews AS (
    SELECT i.i_item_id,
           SUM(pr.pr_sentiment) AS sum_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i_sales.i_category_id,
    i_sales.i_category,
    SUM(i_sales.total_quantity) AS category_total_quantity,
    SUM(i_sales.total_revenue) AS category_total_revenue,
    CASE WHEN SUM(i_reviews.review_count) > 0 THEN SUM(i_reviews.sum_sentiment) / SUM(i_reviews.review_count) ELSE NULL END AS category_avg_sentiment,
    SUM(i_reviews.review_count) AS category_review_count
FROM item_sales i_sales
LEFT JOIN item_reviews i_reviews ON i_reviews.i_item_id = i_sales.i_item_id
GROUP BY i_sales.i_category_id, i_sales.i_category
ORDER BY category_total_quantity DESC
LIMIT 10
