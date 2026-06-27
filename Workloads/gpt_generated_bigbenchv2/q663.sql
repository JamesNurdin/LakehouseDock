WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM items i
    JOIN product_reviews pr
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),

sales_union AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
),

sales_agg AS (
    SELECT su.customer_id,
           su.item_id,
           SUM(su.quantity) AS total_quantity
    FROM sales_union su
    GROUP BY su.customer_id, su.item_id
),

customer_item AS (
    SELECT c.c_customer_id,
           c.c_name,
           s.item_id,
           s.total_quantity,
           ir.avg_rating
    FROM customers c
    JOIN sales_agg s
      ON s.customer_id = c.c_customer_id
    LEFT JOIN item_ratings ir
      ON ir.i_item_id = s.item_id
)
SELECT ci.c_customer_id,
       ci.c_name,
       COUNT(DISTINCT ci.item_id) AS distinct_items,
       SUM(ci.total_quantity) AS total_quantity,
       AVG(ci.avg_rating) AS avg_rating_of_purchased_items
FROM customer_item ci
GROUP BY ci.c_customer_id, ci.c_name
ORDER BY total_quantity DESC
LIMIT 20
