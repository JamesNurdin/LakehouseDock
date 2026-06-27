WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_id,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS total_store_qty,
            SUM(ss.ss_quantity * i.i_price) AS total_store_rev
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_web_qty
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    product_reviews_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT
    s.s_store_name,
    ssagg.i_category_id,
    ssagg.i_category_name,
    ssagg.total_store_qty,
    ssagg.total_store_rev,
    COALESCE(wsagg.total_web_qty, 0) AS total_web_qty,
    COALESCE(pragg.avg_rating, 0) AS avg_rating,
    COALESCE(pragg.review_count, 0) AS review_count
FROM store_sales_agg ssagg
JOIN stores s ON ssagg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wsagg
    ON ssagg.i_category_id = wsagg.i_category_id
    AND ssagg.i_category_name = wsagg.i_category_name
LEFT JOIN product_reviews_agg pragg
    ON ssagg.i_category_id = pragg.i_category_id
    AND ssagg.i_category_name = pragg.i_category_name
ORDER BY ssagg.total_store_rev DESC
LIMIT 100
