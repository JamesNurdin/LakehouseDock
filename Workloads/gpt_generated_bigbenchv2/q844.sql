WITH
    store_agg AS (
        SELECT
            ss.ss_item_id AS i_item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id
    ),
    web_agg AS (
        SELECT
            ws.ws_item_id AS i_item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    review_stats AS (
        SELECT
            i.i_item_id AS i_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    customer_counts AS (
        SELECT
            combined.i_item_id AS i_item_id,
            COUNT(DISTINCT combined.customer_id) AS distinct_customers
        FROM (
            SELECT ss.ss_item_id AS i_item_id, ss.ss_customer_id AS customer_id
            FROM store_sales ss
            UNION ALL
            SELECT ws.ws_item_id AS i_item_id, ws.ws_customer_id AS customer_id
            FROM web_sales ws
        ) AS combined
        GROUP BY combined.i_item_id
    )
SELECT
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(rs.avg_rating, 0) AS avg_rating,
    COALESCE(rs.review_count, 0) AS review_count,
    COALESCE(cc.distinct_customers, 0) AS distinct_customers
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_stats rs ON i.i_item_id = rs.i_item_id
LEFT JOIN customer_counts cc ON i.i_item_id = cc.i_item_id
ORDER BY (COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) DESC
LIMIT 100
