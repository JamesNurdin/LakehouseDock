WITH sales_agg AS (
    SELECT ss_item_id AS item_id, SUM(ss_quantity) AS quantity
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT ws_item_id AS item_id, SUM(ws_quantity) AS quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_price,
        COALESCE(SUM(s.quantity), 0) AS total_quantity_sold
    FROM items i
    LEFT JOIN sales_agg s ON s.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category, i.i_price
),
item_reviews AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i_sales.i_category,
    COUNT(DISTINCT i_sales.i_item_id) AS num_items,
    SUM(i_sales.total_quantity_sold) AS total_quantity_sold,
    AVG(i_reviews.avg_sentiment) AS avg_category_sentiment,
    SUM(i_reviews.review_count) AS total_reviews
FROM item_sales i_sales
LEFT JOIN item_reviews i_reviews ON i_reviews.i_item_id = i_sales.i_item_id
GROUP BY i_sales.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
