WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales AS (
    SELECT ss.ss_quantity AS qty,
           i.i_category_name,
           i.i_item_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_quantity AS qty,
           i.i_category_name,
           i.i_item_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT s.i_category_name,
       SUM(s.qty) AS total_quantity,
       AVG(r.avg_rating) AS avg_item_rating,
       COUNT(DISTINCT s.i_item_id) AS distinct_items_sold
FROM sales s
LEFT JOIN item_ratings r ON s.i_item_id = r.i_item_id
GROUP BY s.i_category_name
ORDER BY total_quantity DESC
