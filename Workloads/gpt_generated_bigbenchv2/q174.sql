WITH sales AS (
    SELECT 
        ss_item_id AS item_id,
        ss_store_id AS store_id,
        ss_quantity AS quantity,
        ss_customer_id AS customer_id
    FROM store_sales
    UNION ALL
    SELECT 
        ws_item_id AS item_id,
        NULL AS store_id,
        ws_quantity AS quantity,
        ws_customer_id AS customer_id
    FROM web_sales
),
sales_agg AS (
    SELECT 
        s.item_id,
        s.store_id,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales s
    JOIN items i ON i.i_item_id = s.item_id
    GROUP BY s.item_id, s.store_id
)
SELECT 
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(st.s_store_name, 'Online') AS sales_channel,
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customers,
    AVG(pr.pr_rating) AS avg_rating,
    COUNT(pr.pr_review_id) AS review_count
FROM sales_agg sa
LEFT JOIN items i ON i.i_item_id = sa.item_id
LEFT JOIN stores st ON st.s_store_id = sa.store_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY 
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(st.s_store_name, 'Online'),
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customers
ORDER BY sa.total_quantity DESC
LIMIT 100
