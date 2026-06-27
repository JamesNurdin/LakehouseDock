WITH
    store_sales_by_store_category AS (
        SELECT
            s.s_store_name AS store_name,
            i.i_category_name AS category_name,
            SUM(ss.ss_quantity) AS total_store_qty,
            SUM(ss.ss_quantity * i.i_price) AS total_store_rev
        FROM store_sales ss
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY s.s_store_name, i.i_category_name
    ),
    web_sales_by_category AS (
        SELECT
            i.i_category_name AS category_name,
            SUM(ws.ws_quantity) AS total_web_qty,
            SUM(ws.ws_quantity * i.i_price) AS total_web_rev
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_name
    ),
    avg_rating_by_category AS (
        SELECT
            i.i_category_name AS category_name,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_name
    )
SELECT
    sc.store_name,
    sc.category_name,
    sc.total_store_qty,
    sc.total_store_rev,
    COALESCE(wc.total_web_qty, 0) AS total_web_qty,
    COALESCE(wc.total_web_rev, 0) AS total_web_rev,
    ar.avg_rating
FROM store_sales_by_store_category sc
LEFT JOIN web_sales_by_category wc
    ON sc.category_name = wc.category_name
LEFT JOIN avg_rating_by_category ar
    ON sc.category_name = ar.category_name
ORDER BY sc.total_store_rev DESC
LIMIT 100
