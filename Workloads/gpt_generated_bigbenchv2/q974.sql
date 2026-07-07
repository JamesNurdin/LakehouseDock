WITH sales_per_item AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(s.quantity) AS total_quantity
    FROM items i
    LEFT JOIN (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity FROM web_sales
    ) s ON s.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
reviews_per_item AS (
    SELECT
        i.i_item_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT
    s.i_category,
    SUM(s.total_quantity) AS total_quantity_sold,
    AVG(r.avg_sentiment) AS avg_review_sentiment,
    SUM(r.review_count) AS total_review_count
FROM sales_per_item s
JOIN reviews_per_item r ON r.i_item_id = s.i_item_id
GROUP BY s.i_category
ORDER BY total_quantity_sold DESC
