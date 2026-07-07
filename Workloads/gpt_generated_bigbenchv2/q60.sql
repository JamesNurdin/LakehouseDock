WITH sales_union AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT s.item_id,
           SUM(s.quantity) AS total_quantity,
           COUNT(*) AS sales_transactions
    FROM sales_union s
    GROUP BY s.item_id
),
item_sentiment AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(isales.total_quantity, 0) AS total_quantity_sold,
       COALESCE(isales.sales_transactions, 0) AS total_sales_transactions,
       isent.avg_sentiment,
       COALESCE(isent.review_count, 0) AS review_count
FROM items i
LEFT JOIN item_sales isales
    ON i.i_item_id = isales.item_id
LEFT JOIN item_sentiment isent
    ON i.i_item_id = isent.item_id
ORDER BY total_quantity_sold DESC
LIMIT 100
