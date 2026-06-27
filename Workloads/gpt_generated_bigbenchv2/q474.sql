WITH
    store_sales_agg AS (
        SELECT
            s.s_store_id   AS store_id,
            s.s_store_name AS store_name,
            i.i_category_id   AS category_id,
            i.i_category_name AS category_name,
            SUM(ss.ss_quantity)                     AS store_quantity,
            COUNT(DISTINCT ss.ss_customer_id)       AS store_customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY
            s.s_store_id,
            s.s_store_name,
            i.i_category_id,
            i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id   AS category_id,
            i.i_category_name AS category_name,
            SUM(ws.ws_quantity)               AS web_quantity,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY
            i.i_category_id,
            i.i_category_name
    ),
    rating_agg AS (
        SELECT
            i.i_category_id   AS category_id,
            i.i_category_name AS category_name,
            AVG(pr.pr_rating)               AS avg_rating,
            COUNT(pr.pr_review_id)          AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY
            i.i_category_id,
            i.i_category_name
    )
SELECT
    ss.store_name,
    ss.category_name,
    ss.store_quantity,
    DENSE_RANK() OVER (PARTITION BY ss.store_name ORDER BY ss.store_quantity DESC) AS category_rank,
    ws.web_quantity,
    ss.store_customer_count,
    ws.web_customer_count,
    ra.avg_rating,
    ra.review_count,
    (ss.store_quantity * 1.0) / NULLIF(ss.store_quantity + ws.web_quantity, 0) AS store_quantity_ratio
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws ON ss.category_id = ws.category_id
LEFT JOIN rating_agg ra   ON ss.category_id = ra.category_id
ORDER BY ss.store_quantity DESC
LIMIT 100
