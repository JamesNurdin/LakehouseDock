WITH store_agg AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT
    sa.s_store_name,
    sa.i_category_name,
    sa.total_store_quantity,
    sa.total_store_revenue,
    wa.total_web_quantity,
    wa.total_web_revenue,
    ra.avg_rating,
    ra.review_count,
    sa.distinct_store_customers,
    wa.distinct_web_customers
FROM store_agg sa
LEFT JOIN web_agg wa ON sa.i_category_name = wa.i_category_name
LEFT JOIN review_agg ra ON sa.i_category_name = ra.i_category_name
ORDER BY sa.s_store_name, sa.i_category_name
