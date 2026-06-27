WITH
    store_agg AS (
        SELECT
            ss.ss_store_id,
            ss.ss_item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
        FROM store_sales ss
        GROUP BY ss.ss_store_id, ss.ss_item_id
    ),
    web_agg AS (
        SELECT
            ws.ws_item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
        FROM web_sales ws
        GROUP BY ws.ws_item_id
    ),
    review_agg AS (
        SELECT
            pr.pr_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    item_info AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            i.i_price,
            i.i_comp_price,
            i.i_class_id
        FROM items i
    )
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    sa.store_quantity,
    sa.store_customer_count,
    COALESCE(wa.web_quantity, 0)        AS web_quantity,
    COALESCE(wa.web_customer_count, 0) AS web_customer_count,
    COALESCE(ra.avg_rating, 0)          AS avg_rating,
    COALESCE(ra.review_count, 0)       AS review_count
FROM store_agg sa
JOIN stores s       ON sa.ss_store_id = s.s_store_id
JOIN item_info i    ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa   ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
WHERE sa.store_quantity > 0
ORDER BY sa.store_quantity DESC
LIMIT 100
