WITH avg_sentiment AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
sales AS (
    SELECT i_item_id,
           SUM(quantity) AS total_quantity
    FROM (
        SELECT ss_item_id AS i_item_id,
               ss_quantity AS quantity
        FROM store_sales
        UNION ALL
        SELECT ws_item_id AS i_item_id,
               ws_quantity AS quantity
        FROM web_sales
    ) AS combined
    GROUP BY i_item_id
)
SELECT items.i_item_id,
       items.i_name,
       items.i_category,
       avg_sentiment.avg_sentiment,
       sales.total_quantity,
       items.i_price * sales.total_quantity AS revenue
FROM items
JOIN avg_sentiment
  ON items.i_item_id = avg_sentiment.i_item_id
JOIN sales
  ON items.i_item_id = sales.i_item_id
WHERE avg_sentiment.avg_sentiment >= 3
ORDER BY revenue DESC
LIMIT 5
