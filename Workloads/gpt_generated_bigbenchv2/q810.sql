WITH store_category_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS unique_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
online_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_online_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_online_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_reviews AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    cs.i_category_name,
    cs.total_store_quantity,
    cs.total_store_revenue,
    cs.unique_store_customers,
    oc.total_online_quantity,
    oc.total_online_revenue,
    cr.avg_rating,
    cr.review_count,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY cs.total_store_revenue DESC) AS revenue_rank
FROM store_category_sales cs
JOIN stores s ON cs.ss_store_id = s.s_store_id
LEFT JOIN online_category_sales oc ON cs.i_category_id = oc.i_category_id
LEFT JOIN category_reviews cr ON cs.i_category_id = cr.i_category_id
WHERE cs.total_store_quantity > 0
ORDER BY s.s_store_name, revenue_rank
LIMIT 100
