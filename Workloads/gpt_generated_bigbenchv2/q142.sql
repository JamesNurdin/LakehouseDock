WITH sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity, 'store' AS channel FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity, 'web' AS channel FROM web_sales
),
sales_agg AS (
    SELECT i.i_category AS category,
           SUM(s.quantity) AS total_quantity,
           SUM(CASE WHEN s.channel = 'store' THEN s.quantity ELSE 0 END) AS store_quantity,
           SUM(CASE WHEN s.channel = 'web' THEN s.quantity ELSE 0 END) AS web_quantity
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT s.category,
       s.total_quantity,
       s.store_quantity,
       s.web_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN reviews_agg r ON s.category = r.category
ORDER BY s.total_quantity DESC
LIMIT 10
