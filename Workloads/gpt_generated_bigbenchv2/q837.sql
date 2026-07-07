WITH sales AS (
    SELECT i.i_category_id,
           i.i_category,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category_id,
           i.i_category,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT i_category_id,
           i_category,
           SUM(quantity) AS total_quantity,
           COUNT(*) AS sales_count
    FROM sales
    GROUP BY i_category_id, i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT s.i_category_id,
       s.i_category,
       s.total_quantity,
       s.sales_count,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.i_category_id = r.i_category_id
WHERE s.total_quantity > 0
ORDER BY s.total_quantity DESC
LIMIT 10
