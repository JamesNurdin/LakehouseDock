WITH sales AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
item_sales_agg AS (
    SELECT i_item_id,
           i_category,
           i_category_id,
           SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY i_item_id, i_category, i_category_id
),
item_reviews AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           SUM(pr.pr_sentiment) AS sum_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category, i.i_category_id
)
SELECT
    s.i_category,
    s.i_category_id,
    SUM(s.total_quantity) AS total_quantity_sold,
    CASE WHEN SUM(r.review_count) > 0 THEN SUM(r.sum_sentiment) / SUM(r.review_count) END AS avg_review_sentiment,
    SUM(r.review_count) AS total_reviews
FROM item_sales_agg s
LEFT JOIN item_reviews r ON s.i_item_id = r.i_item_id
GROUP BY s.i_category, s.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
