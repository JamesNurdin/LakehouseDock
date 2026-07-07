WITH unified_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_by_item AS (
    SELECT us.item_id,
           SUM(us.quantity) AS total_quantity
    FROM unified_sales us
    GROUP BY us.item_id
),
review_by_item AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category,
    SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
    AVG(r.avg_sentiment) AS avg_review_sentiment,
    SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN sales_by_item s ON s.item_id = i.i_item_id
LEFT JOIN review_by_item r ON r.item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
