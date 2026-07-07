WITH item_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
item_sales_agg AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM item_sales
    GROUP BY item_id
),
item_sentiment AS (
    SELECT pr_item_id AS item_id, AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    COUNT(DISTINCT i.i_item_id) AS num_items,
    SUM(COALESCE(sa.total_quantity, 0)) AS total_quantity_sold,
    AVG(i.i_price) AS avg_item_price,
    AVG(se.avg_sentiment) AS avg_item_sentiment
FROM items i
LEFT JOIN item_sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN item_sentiment se ON i.i_item_id = se.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
