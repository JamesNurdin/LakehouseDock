WITH review_stats AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_name,
        ss.ss_customer_id AS customer_id,
        ss.ss_quantity AS quantity,
        i.i_price * ss.ss_quantity AS revenue,
        rs.avg_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN review_stats rs ON i.i_item_id = rs.item_id
),
web_sales_agg AS (
    SELECT
        NULL AS store_id,
        i.i_category_name,
        ws.ws_customer_id AS customer_id,
        ws.ws_quantity AS quantity,
        i.i_price * ws.ws_quantity AS revenue,
        rs.avg_rating
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN review_stats rs ON i.i_item_id = rs.item_id
),
sales_union AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
store_names AS (
    SELECT s_store_id, s_store_name FROM stores
)
SELECT
    COALESCE(sn.s_store_name, 'Online') AS store_name,
    su.i_category_name,
    SUM(su.quantity) AS total_quantity,
    SUM(su.revenue) AS total_revenue,
    AVG(su.avg_rating) AS avg_item_rating,
    COUNT(DISTINCT su.customer_id) AS distinct_customers
FROM sales_union su
LEFT JOIN store_names sn ON su.store_id = sn.s_store_id
GROUP BY COALESCE(sn.s_store_name, 'Online'), su.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
