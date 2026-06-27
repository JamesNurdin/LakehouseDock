WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT c.c_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT c.c_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sa.category_id,
    sa.category_name,
    sa.total_store_quantity,
    sa.total_store_revenue,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wa.total_web_revenue, 0) AS total_web_revenue,
    sa.distinct_store_customers,
    COALESCE(wa.distinct_web_customers, 0) AS distinct_web_customers,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count
FROM stores s
JOIN store_sales_agg sa
    ON s.s_store_id = sa.store_id
LEFT JOIN web_sales_agg wa
    ON wa.category_id = sa.category_id
LEFT JOIN review_agg ra
    ON ra.category_id = sa.category_id
ORDER BY s.s_store_id, sa.category_id
