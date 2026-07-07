WITH review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(COALESCE(s.quantity, 0)) AS total_quantity_sold,
    AVG(r.avg_sentiment) AS avg_sentiment,
    SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity FROM web_sales
) s ON i.i_item_id = s.item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
