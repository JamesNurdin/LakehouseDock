WITH combined_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_ts AS ts
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_ts AS ts
    FROM web_sales
)
SELECT c.c_customer_id,
       c.c_name,
       i.i_category,
       SUM(cs.quantity) AS total_quantity,
       SUM(cs.quantity * i.i_price) AS total_revenue
FROM combined_sales cs
JOIN customers c ON cs.customer_id = c.c_customer_id
JOIN items i ON cs.item_id = i.i_item_id
GROUP BY c.c_customer_id, c.c_name, i.i_category
ORDER BY total_revenue DESC
LIMIT 100
