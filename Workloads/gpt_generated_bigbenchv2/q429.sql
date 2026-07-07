WITH sales_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           i.i_category_id,
           SUM(s.quantity) AS total_quantity_sold
    FROM (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity
        FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity
        FROM web_sales
    ) AS s
    JOIN items i ON i.i_item_id = s.item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category, i.i_category_id
),
reviews_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_item_id
)
SELECT s.i_item_id,
       s.i_name,
       s.i_category,
       s.total_quantity_sold,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM sales_agg s
LEFT JOIN reviews_agg r ON r.i_item_id = s.i_item_id
ORDER BY s.total_quantity_sold DESC
LIMIT 10
