WITH sales_union AS (
    SELECT i.i_item_id,
           i.i_category,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_item_id,
           i.i_category,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT i_item_id,
           i_category,
           SUM(quantity) AS total_quantity
    FROM sales_union
    GROUP BY i_item_id, i_category
),
review_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT s.i_category,
       SUM(s.total_quantity) AS total_quantity_sold,
       AVG(r.avg_sentiment) AS avg_sentiment_per_category,
       SUM(r.review_count) AS total_reviews
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_item_id = r.i_item_id
GROUP BY s.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
