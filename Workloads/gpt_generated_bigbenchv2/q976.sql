WITH
    store_agg AS (
        SELECT
            i.i_category,
            SUM(ss.ss_quantity) AS total_store_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category
    ),
    web_agg AS (
        SELECT
            i.i_category,
            SUM(ws.ws_quantity) AS total_web_quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category
    ),
    review_agg AS (
        SELECT
            i.i_category,
            AVG(pr.pr_sentiment) AS avg_sentiment,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category
    ),
    categories AS (
        SELECT DISTINCT i.i_category
        FROM items i
    )
SELECT
    cat.i_category,
    COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0) AS total_quantity_sold,
    COALESCE(sa.total_store_quantity, 0) AS store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS web_quantity,
    ra.avg_sentiment,
    ra.review_count
FROM categories cat
LEFT JOIN store_agg sa ON cat.i_category = sa.i_category
LEFT JOIN web_agg wa ON cat.i_category = wa.i_category
LEFT JOIN review_agg ra ON cat.i_category = ra.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
