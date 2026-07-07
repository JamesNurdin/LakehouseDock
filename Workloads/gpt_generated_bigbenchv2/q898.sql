WITH store_sales_data AS (
    SELECT s.s_store_name AS store_name,
           i.i_category AS category,
           ss.ss_customer_id AS customer_id,
           ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN stores s
      ON ss.ss_store_id = s.s_store_id
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
),
web_sales_data AS (
    SELECT 'Online' AS store_name,
           i.i_category AS category,
           ws.ws_customer_id AS customer_id,
           ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
)
SELECT store_name,
       category,
       SUM(revenue) AS total_revenue,
       COUNT(DISTINCT customer_id) AS distinct_customers
FROM (
    SELECT store_name, category, customer_id, revenue FROM store_sales_data
    UNION ALL
    SELECT store_name, category, customer_id, revenue FROM web_sales_data
) AS unified_sales
GROUP BY store_name, category
ORDER BY total_revenue DESC
LIMIT 20
