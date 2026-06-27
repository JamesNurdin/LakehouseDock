WITH
    store_item_sales_agg AS (
        SELECT
            ss.ss_item_id,
            ss.ss_store_id,
            SUM(ss.ss_quantity) AS quantity,
            SUM(ss.ss_quantity * i.i_price) AS revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY ss.ss_item_id, ss.ss_store_id
    ),
    top_store_per_item AS (
        SELECT
            ss_item_id,
            ss_store_id,
            quantity,
            revenue,
            ROW_NUMBER() OVER (PARTITION BY ss_item_id ORDER BY quantity DESC) AS store_rank
        FROM store_item_sales_agg
    ),
    top_store AS (
        SELECT
            ss_item_id,
            ss_store_id,
            quantity,
            revenue
        FROM top_store_per_item
        WHERE store_rank = 1
    ),
    store_sales_agg AS (
        SELECT
            i.i_item_id,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_id,
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
    ),
    reviews_agg AS (
        SELECT
            i.i_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(sa.store_customer_count, 0) + COALESCE(wa.web_customer_count, 0) AS total_customers,
    ra.avg_rating,
    ra.review_count,
    ts.ss_store_id AS top_store_id,
    s.s_store_name AS top_store_name,
    ts.quantity AS top_store_quantity,
    ts.revenue AS top_store_revenue
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN reviews_agg ra ON i.i_item_id = ra.i_item_id
LEFT JOIN top_store ts ON i.i_item_id = ts.ss_item_id
LEFT JOIN stores s ON ts.ss_store_id = s.s_store_id
ORDER BY total_revenue DESC
LIMIT 20
