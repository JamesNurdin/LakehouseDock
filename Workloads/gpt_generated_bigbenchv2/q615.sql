WITH
    store_agg AS (
        SELECT
            ss.ss_item_id AS item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customers,
            COUNT(DISTINCT ss.ss_store_id) AS distinct_stores
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id
    ),
    web_agg AS (
        SELECT
            ws.ws_item_id AS item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customers
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    review_agg AS (
        SELECT
            pr.pr_item_id AS item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    customer_agg AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_customers
        FROM (
            SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id
            FROM store_sales ss
            UNION ALL
            SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id
            FROM web_sales ws
        ) u
        GROUP BY item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(ca.distinct_customers, 0) AS distinct_customers,
    COALESCE(sa.distinct_stores, 0) AS distinct_stores,
    ra.avg_rating,
    i.i_price AS item_price,
    ra.review_count
FROM items i
LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.item_id = i.i_item_id
LEFT JOIN customer_agg ca ON ca.item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 50
