WITH item_sales AS (
        SELECT ss_item_id AS i_item_id, ss_quantity AS quantity
        FROM store_sales
        UNION ALL
        SELECT ws_item_id AS i_item_id, ws_quantity AS quantity
        FROM web_sales
    ),
    sales_agg AS (
        SELECT i_item_id, SUM(quantity) AS total_quantity
        FROM item_sales
        GROUP BY i_item_id
    ),
    rating_agg AS (
        SELECT pr_item_id AS i_item_id, AVG(pr_rating) AS avg_rating, COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    )
SELECT
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(sa.total_quantity) AS total_quantity_sold,
    SUM(i.i_price * sa.total_quantity) AS total_revenue,
    AVG(ra.avg_rating) AS avg_item_rating,
    SUM(ra.review_count) AS total_reviews
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN rating_agg ra ON i.i_item_id = ra.i_item_id
GROUP BY i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
