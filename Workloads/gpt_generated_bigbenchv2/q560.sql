WITH
store_agg_cat AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_agg_cat AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg_cat AS (
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
    COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id) AS i_category_id,
    COALESCE(sa.i_category_name, wa.i_category_name, ra.i_category_name) AS i_category_name,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(sa.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wa.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(sa.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(wa.distinct_web_customers, 0) AS distinct_web_customers,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count
FROM store_agg_cat sa
FULL OUTER JOIN web_agg_cat wa
    ON sa.i_category_id = wa.i_category_id
FULL OUTER JOIN review_agg_cat ra
    ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
ORDER BY total_store_revenue DESC
LIMIT 50
