WITH all_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM all_sales
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    SUM(sa.total_quantity) AS total_quantity_sold,
    AVG(ra.avg_sentiment) AS avg_review_sentiment,
    SUM(ra.review_count) AS total_reviews
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
