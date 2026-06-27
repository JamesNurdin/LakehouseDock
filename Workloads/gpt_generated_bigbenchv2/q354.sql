WITH
    store_item_sales AS (
        SELECT
            ss_item_id,
            ss_store_id,
            SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id, ss_store_id
    ),
    store_item_rank AS (
        SELECT
            ss_item_id,
            ss_store_id,
            store_quantity,
            ROW_NUMBER() OVER (PARTITION BY ss_item_id ORDER BY store_quantity DESC) AS rn
        FROM store_item_sales
    ),
    store_agg AS (
        SELECT
            ss_item_id,
            SUM(store_quantity) AS total_store_quantity,
            MAX(CASE WHEN rn = 1 THEN ss_store_id END) AS top_store_id
        FROM store_item_rank
        GROUP BY ss_item_id
    ),
    web_item_sales AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS total_web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ),
    review_agg AS (
        SELECT
            pr_item_id,
            AVG(pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    customer_item AS (
        SELECT ss_item_id AS item_id, ss_customer_id AS customer_id
        FROM store_sales
        UNION
        SELECT ws_item_id AS item_id, ws_customer_id AS customer_id
        FROM web_sales
    ),
    customer_agg AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_customer_count
        FROM customer_item
        GROUP BY item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0) AS total_quantity,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count,
    COALESCE(ca.distinct_customer_count, 0) AS distinct_customer_count,
    s.s_store_name AS top_store_name
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_item_sales wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
LEFT JOIN customer_agg ca ON i.i_item_id = ca.item_id
LEFT JOIN stores s ON sa.top_store_id = s.s_store_id
ORDER BY total_quantity DESC
LIMIT 100
