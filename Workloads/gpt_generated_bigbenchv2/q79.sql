WITH sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_customer_id AS customer_id,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        NULL AS store_id,
        ws.ws_customer_id AS customer_id,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_ratings AS (
    SELECT
        i.i_category_id AS category_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
),
sales_agg AS (
    SELECT
        s.store_id,
        s.category_id,
        s.category_name,
        SUM(s.revenue) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS distinct_customers,
        cr.avg_rating
    FROM sales s
    LEFT JOIN category_ratings cr ON s.category_id = cr.category_id
    GROUP BY s.store_id, s.category_id, s.category_name, cr.avg_rating
)
SELECT
    COALESCE(sa.store_id, -1) AS store_id,
    st.s_store_name,
    sa.category_id,
    sa.category_name,
    sa.total_revenue,
    sa.distinct_customers,
    sa.avg_rating
FROM sales_agg sa
LEFT JOIN stores st ON sa.store_id = st.s_store_id
ORDER BY sa.total_revenue DESC
LIMIT 50
