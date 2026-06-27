/*
  Sales performance by store (including online) and item category with weighted average rating.
  The query aggregates physical store sales and web sales, joins to item information and
  product review ratings, and returns the top 10 store‑channel / category combinations
  by revenue.
*/
WITH store_sales_cte AS (
    SELECT
        s.s_store_name AS store_name,
        'store' AS sales_channel,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
),
web_sales_cte AS (
    SELECT
        'Online' AS store_name,
        'web' AS sales_channel,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
),
combined_sales AS (
    SELECT * FROM store_sales_cte
    UNION ALL
    SELECT * FROM web_sales_cte
),
item_ratings AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    cs.store_name,
    cs.sales_channel,
    cs.i_category_id,
    cs.i_category_name,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.quantity * cs.price) AS total_revenue,
    COUNT(DISTINCT cs.customer_id) AS distinct_customers,
    SUM(cs.quantity * ir.avg_rating) / NULLIF(SUM(cs.quantity), 0) AS weighted_avg_rating
FROM combined_sales cs
LEFT JOIN item_ratings ir
    ON cs.item_id = ir.pr_item_id
GROUP BY
    cs.store_name,
    cs.sales_channel,
    cs.i_category_id,
    cs.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
