WITH customer_spend AS (
  SELECT
    ws.ws_customer_id,
    SUM(ws.ws_quantity * i.i_price) AS total_spent,
    COUNT(DISTINCT ws.ws_item_id) AS distinct_items
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY ws.ws_customer_id
),
category_quantity AS (
  SELECT
    ws.ws_customer_id,
    i.i_category,
    SUM(ws.ws_quantity) AS quantity_in_category
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY ws.ws_customer_id, i.i_category
),
customer_top_category AS (
  SELECT
    ws_customer_id,
    i_category,
    quantity_in_category,
    ROW_NUMBER() OVER (PARTITION BY ws_customer_id ORDER BY quantity_in_category DESC) AS rn
  FROM category_quantity
)
SELECT
  c.c_customer_id,
  c.c_name,
  cs.total_spent,
  cs.distinct_items,
  ct.i_category AS top_category,
  ct.quantity_in_category AS top_category_quantity
FROM customers c
JOIN customer_spend cs ON c.c_customer_id = cs.ws_customer_id
JOIN (
  SELECT ws_customer_id, i_category, quantity_in_category
  FROM customer_top_category
  WHERE rn = 1
) ct ON c.c_customer_id = ct.ws_customer_id
ORDER BY cs.total_spent DESC
LIMIT 10
