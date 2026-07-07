WITH unified_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
review_agg AS (
    SELECT i.i_category,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
sales_agg AS (
    SELECT i.i_category,
           SUM(us.quantity) AS total_quantity
    FROM unified_sales us
    JOIN items i ON us.item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT r.i_category AS category,
       r.review_count,
       r.avg_sentiment,
       s.total_quantity
FROM review_agg r
JOIN sales_agg s ON r.i_category = s.i_category
ORDER BY r.avg_sentiment DESC, s.total_quantity DESC
LIMIT 10
