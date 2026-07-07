WITH combined_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM combined_sales
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id, AVG(pr_sentiment) AS avg_sentiment, COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(sa.total_quantity, 0) AS total_quantity_sold,
       ra.avg_sentiment,
       ra.review_count
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_quantity_sold DESC
LIMIT 20
