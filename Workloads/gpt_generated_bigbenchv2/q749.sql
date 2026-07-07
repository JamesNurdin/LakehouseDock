WITH sales_agg AS (
    SELECT ws.ws_customer_id,
           ws.ws_item_id,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    GROUP BY ws.ws_customer_id, ws.ws_item_id
),
item_sentiment AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT c.c_name AS customer_name,
       i.i_category AS category,
       SUM(s.total_quantity) AS total_quantity,
       SUM(s.total_quantity * i.i_price) AS total_spent,
       AVG(isent.avg_sentiment) AS avg_sentiment
FROM sales_agg s
JOIN customers c
  ON s.ws_customer_id = c.c_customer_id
JOIN items i
  ON s.ws_item_id = i.i_item_id
LEFT JOIN item_sentiment isent
  ON i.i_item_id = isent.pr_item_id
GROUP BY c.c_name, i.i_category
ORDER BY total_spent DESC
LIMIT 100
