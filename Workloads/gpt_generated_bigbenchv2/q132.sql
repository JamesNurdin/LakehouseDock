WITH store_rev AS (
    SELECT ss_customer_id AS customer_id,
           i.i_category AS category,
           ss_quantity * i.i_price AS revenue
    FROM store_sales
    JOIN items i ON store_sales.ss_item_id = i.i_item_id
),
web_rev AS (
    SELECT ws_customer_id AS customer_id,
           i.i_category AS category,
           ws_quantity * i.i_price AS revenue
    FROM web_sales
    JOIN items i ON web_sales.ws_item_id = i.i_item_id
),
combined_rev AS (
    SELECT customer_id, category, revenue FROM store_rev
    UNION ALL
    SELECT customer_id, category, revenue FROM web_rev
)
SELECT c.c_customer_id,
       c.c_name,
       combined_rev.category,
       SUM(combined_rev.revenue) AS total_revenue,
       COUNT(*) AS transaction_count
FROM combined_rev
JOIN customers c ON combined_rev.customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name, combined_rev.category
ORDER BY total_revenue DESC
LIMIT 20
