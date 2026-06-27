WITH
    store_sales_agg AS (
        SELECT
            ss.ss_item_id,
            ss.ss_store_id,
            SUM(ss.ss_quantity) AS total_store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id, ss.ss_store_id
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id,
            SUM(ws.ws_quantity) AS total_web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    product_reviews_agg AS (
        SELECT
            pr.pr_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    store_names AS (
        SELECT s.s_store_id, s.s_store_name
        FROM stores s
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(sa.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wa.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(sa.distinct_store_customers, 0) + COALESCE(wa.distinct_web_customers, 0) AS total_distinct_customers,
    pr.avg_rating,
    pr.review_count,
    COALESCE(st.s_store_name, 'All Stores') AS store_name,
    (COALESCE(sa.total_store_revenue, 0) + COALESCE(wa.total_web_revenue, 0)) AS total_revenue,
    RANK() OVER (ORDER BY (COALESCE(sa.total_store_revenue, 0) + COALESCE(wa.total_web_revenue, 0)) DESC) AS revenue_rank
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN store_names st ON sa.ss_store_id = st.s_store_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN product_reviews_agg pr ON i.i_item_id = pr.pr_item_id
ORDER BY total_revenue DESC
LIMIT 20
