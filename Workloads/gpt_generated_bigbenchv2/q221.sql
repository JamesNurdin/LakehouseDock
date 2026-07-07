WITH review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_store_id AS store_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_agg AS (
    SELECT ws.ws_customer_id AS customer_id,
           NULL AS store_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT customer_id,
           store_id,
           item_id,
           quantity,
           revenue
    FROM store_sales_agg
    UNION ALL
    SELECT customer_id,
           store_id,
           item_id,
           quantity,
           revenue
    FROM web_sales_agg
)
SELECT i.i_category_id,
       i.i_category,
       SUM(cs.quantity) AS total_quantity_sold,
       SUM(cs.revenue) AS total_revenue,
       AVG(COALESCE(r.avg_sentiment, 0)) AS avg_sentiment,
       COUNT(DISTINCT cs.customer_id) AS distinct_customers,
       COUNT(DISTINCT cs.item_id) AS distinct_items
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
