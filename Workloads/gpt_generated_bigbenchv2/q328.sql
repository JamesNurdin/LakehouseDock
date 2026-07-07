WITH sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT s.item_id,
           SUM(s.quantity) AS total_quantity
    FROM sales s
    GROUP BY s.item_id
),
item_reviews AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(isales.total_quantity, 0) AS total_quantity_sold,
       COALESCE(isales.total_quantity, 0) * i.i_price AS total_revenue,
       ir.avg_sentiment
FROM items i
LEFT JOIN item_sales isales
    ON i.i_item_id = isales.item_id
LEFT JOIN item_reviews ir
    ON i.i_item_id = ir.item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
