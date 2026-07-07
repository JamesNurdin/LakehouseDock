WITH sales AS (
    SELECT ss_item_id AS item_id, SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT ws_item_id AS item_id, SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_item_id
),

sales_agg AS (
    SELECT item_id, SUM(total_quantity) AS total_quantity_sold
    FROM sales
    GROUP BY item_id
),

reviews AS (
    SELECT pr_item_id AS item_id, AVG(pr_sentiment) AS avg_sentiment, COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(sa.total_quantity_sold, 0) AS total_quantity_sold,
       r.avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN reviews r ON i.i_item_id = r.item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
