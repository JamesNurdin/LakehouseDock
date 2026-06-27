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
    review_agg AS (
        SELECT
            pr.pr_item_id AS i_item_id,
            COUNT(*) AS review_count,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS item_count,
    COALESCE(SUM(sa.store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(wa.web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(sa.store_quantity), 0) + COALESCE(SUM(wa.web_quantity), 0) AS total_quantity,
    COALESCE(SUM(sa.store_revenue), 0) + COALESCE(SUM(wa.web_revenue), 0) AS total_revenue,
    COALESCE(SUM(ra.review_count), 0) AS total_reviews,
    CASE
        WHEN COALESCE(SUM(ra.review_count), 0) > 0 THEN
            ROUND(SUM(ra.avg_rating * ra.review_count) / SUM(ra.review_count), 2)
        ELSE NULL
    END AS avg_rating
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
