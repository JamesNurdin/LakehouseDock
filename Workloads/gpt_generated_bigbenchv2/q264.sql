WITH unified_sales AS (
    SELECT ss_item_id AS i_item_id,
           ss_quantity AS quantity,
           ss_store_id AS store_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS i_item_id,
           ws_quantity AS quantity,
           CAST(NULL AS BIGINT) AS store_id
    FROM web_sales
),
item_sales AS (
    SELECT us.i_item_id,
           SUM(us.quantity) AS total_quantity,
           SUM(CASE WHEN us.store_id IS NOT NULL THEN us.quantity ELSE 0 END) AS total_store_quantity,
           SUM(CASE WHEN us.store_id IS NULL THEN us.quantity ELSE 0 END) AS total_web_quantity
    FROM unified_sales us
    GROUP BY us.i_item_id
),
item_ratings AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
store_item_sales AS (
    SELECT us.i_item_id,
           us.store_id,
           SUM(us.quantity) AS store_quantity
    FROM unified_sales us
    WHERE us.store_id IS NOT NULL
    GROUP BY us.i_item_id, us.store_id
),
ranked_store_sales AS (
    SELECT sis.i_item_id,
           sis.store_id,
           sis.store_quantity,
           ROW_NUMBER() OVER (PARTITION BY sis.i_item_id ORDER BY sis.store_quantity DESC) AS store_rank
    FROM store_item_sales sis
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       isales.total_quantity,
       ir.avg_rating,
       ir.review_count,
       s.s_store_name AS top_store_name,
       rs.store_quantity AS top_store_quantity
FROM item_sales isales
JOIN items i ON i.i_item_id = isales.i_item_id
LEFT JOIN item_ratings ir ON ir.i_item_id = i.i_item_id
LEFT JOIN ranked_store_sales rs ON rs.i_item_id = i.i_item_id AND rs.store_rank = 1
LEFT JOIN stores s ON s.s_store_id = rs.store_id
ORDER BY isales.total_quantity DESC
LIMIT 10
