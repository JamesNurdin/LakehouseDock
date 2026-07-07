WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           i.i_price,
           SUM(s.quantity) AS total_quantity,
           SUM(s.quantity) * i.i_price AS total_revenue
    FROM items i
    JOIN sales s ON s.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category, i.i_price
),
item_sentiment AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT isales.i_category,
       SUM(isales.total_quantity) AS category_total_quantity,
       SUM(isales.total_revenue) AS category_total_revenue,
       AVG(isent.avg_sentiment) AS category_avg_sentiment
FROM item_sales isales
LEFT JOIN item_sentiment isent ON isent.i_item_id = isales.i_item_id
GROUP BY isales.i_category
ORDER BY category_total_revenue DESC
LIMIT 5
