WITH sales AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_store_id AS store_id,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        NULL AS store_id,
        'web' AS channel
    FROM web_sales ws
),
item_ratings AS (
    SELECT
        pr_item_id AS item_id,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    COALESCE(st.s_store_name, 'Online') AS sales_channel,
    i.i_category_name,
    SUM(s.quantity) AS total_quantity,
    SUM(s.quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS distinct_customers,
    AVG(ir.avg_rating) AS avg_item_rating
FROM sales s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN stores st ON s.store_id = st.s_store_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.item_id
GROUP BY COALESCE(st.s_store_name, 'Online'), i.i_category_name
ORDER BY total_revenue DESC
