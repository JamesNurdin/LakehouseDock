WITH
    categories AS (
        SELECT DISTINCT i_category_id, i_category_name
        FROM items
    ),
    store_agg AS (
        SELECT i.i_category_id AS category_id,
               SUM(ss.ss_quantity) AS store_quantity,
               SUM(ss.ss_quantity * i.i_price) AS store_revenue,
               COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        GROUP BY i.i_category_id
    ),
    web_agg AS (
        SELECT i.i_category_id AS category_id,
               SUM(ws.ws_quantity) AS web_quantity,
               SUM(ws.ws_quantity * i.i_price) AS web_revenue,
               COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
        GROUP BY i.i_category_id
    ),
    rating_agg AS (
        SELECT i.i_category_id AS category_id,
               AVG(pr.pr_rating) AS avg_rating,
               COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id
    ),
    distinct_customers AS (
        SELECT category_id,
               COUNT(DISTINCT cust_id) AS distinct_customer_count
        FROM (
            SELECT ss.ss_customer_id AS cust_id,
                   i.i_category_id AS category_id
            FROM store_sales ss
            JOIN items i ON ss.ss_item_id = i.i_item_id
            UNION ALL
            SELECT ws.ws_customer_id AS cust_id,
                   i.i_category_id AS category_id
            FROM web_sales ws
            JOIN items i ON ws.ws_item_id = i.i_item_id
        ) uc
        GROUP BY category_id
    )
SELECT
    cat.i_category_id AS category_id,
    cat.i_category_name AS category_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count,
    COALESCE(dc.distinct_customer_count, 0) AS distinct_customer_count
FROM categories cat
LEFT JOIN store_agg sa ON cat.i_category_id = sa.category_id
LEFT JOIN web_agg wa ON cat.i_category_id = wa.category_id
LEFT JOIN rating_agg ra ON cat.i_category_id = ra.category_id
LEFT JOIN distinct_customers dc ON cat.i_category_id = dc.category_id
ORDER BY total_revenue DESC
LIMIT 10
