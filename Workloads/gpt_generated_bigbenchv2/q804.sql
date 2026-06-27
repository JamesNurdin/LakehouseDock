WITH sales_per_item AS (
        SELECT ss_item_id AS item_id,
               SUM(ss_quantity) AS quantity
        FROM store_sales
        GROUP BY ss_item_id
        UNION ALL
        SELECT ws_item_id AS item_id,
               SUM(ws_quantity) AS quantity
        FROM web_sales
        GROUP BY ws_item_id
    ),
    total_sales AS (
        SELECT item_id,
               SUM(quantity) AS total_quantity
        FROM sales_per_item
        GROUP BY item_id
    ),
    avg_rating AS (
        SELECT pr_item_id AS item_id,
               AVG(pr_rating) AS avg_rating
        FROM product_reviews
        GROUP BY pr_item_id
    )
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(ts.total_quantity) AS total_quantity_sold,
    SUM(ts.total_quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
    AVG(ar.avg_rating) AS avg_item_rating
FROM total_sales ts
JOIN items i ON ts.item_id = i.i_item_id
LEFT JOIN avg_rating ar ON i.i_item_id = ar.item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
