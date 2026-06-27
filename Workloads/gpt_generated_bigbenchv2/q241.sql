WITH sales_combined AS (
    SELECT ss.ss_store_id AS store_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION ALL
    SELECT NULL AS store_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        COALESCE(s.store_id, -1) AS store_id,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales_combined s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY
        COALESCE(s.store_id, -1),
        i.i_category_id,
        i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    CASE WHEN sa.store_id = -1 THEN 'Online' ELSE CAST(sa.store_id AS varchar) END AS store_identifier,
    s.s_store_name,
    sa.category_id,
    sa.category_name,
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customers,
    ra.avg_rating,
    ra.review_count
FROM sales_agg sa
LEFT JOIN reviews_agg ra ON sa.category_id = ra.category_id
LEFT JOIN stores s ON sa.store_id = s.s_store_id
ORDER BY sa.total_revenue DESC
LIMIT 20
