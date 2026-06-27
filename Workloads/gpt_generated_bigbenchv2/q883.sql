WITH
    store_agg AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            i.i_price,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(i.i_price * ss.ss_quantity) AS store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt,
            COUNT(DISTINCT ss.ss_store_id) AS store_cnt
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price
    ),
    web_agg AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            i.i_price,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(i.i_price * ws.ws_quantity) AS web_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price
    ),
    review_agg AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_cnt
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name
    ),
    customer_agg AS (
        SELECT
            item_id,
            COUNT(DISTINCT cust_id) AS total_customer_cnt
        FROM (
            SELECT ss.ss_customer_id AS cust_id, ss.ss_item_id AS item_id FROM store_sales ss
            UNION ALL
            SELECT ws.ws_customer_id AS cust_id, ws.ws_item_id AS item_id FROM web_sales ws
        ) AS combined
        GROUP BY item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_cnt, 0) AS review_cnt,
    COALESCE(ca.total_customer_cnt, 0) AS distinct_customer_cnt,
    COALESCE(sa.store_cnt, 0) AS distinct_store_cnt
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
LEFT JOIN customer_agg ca ON i.i_item_id = ca.item_id
WHERE COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) > 0
ORDER BY total_revenue DESC
LIMIT 10
