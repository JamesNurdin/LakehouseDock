WITH
    store_agg AS (
        SELECT
            i.i_category_id,
            i.i_category,
            SUM(ss.ss_quantity) AS total_store_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category
    ),
    web_agg AS (
        SELECT
            i.i_category_id,
            i.i_category,
            SUM(ws.ws_quantity) AS total_web_quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category
    ),
    review_agg AS (
        SELECT
            i.i_category_id,
            i.i_category,
            AVG(pr.pr_sentiment) AS avg_review_sentiment,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category
    ),
    price_agg AS (
        SELECT
            i.i_category_id,
            i.i_category,
            AVG(i.i_price) AS avg_item_price
        FROM items i
        GROUP BY i.i_category_id, i.i_category
    )
SELECT
    COALESCE(pa.i_category_id, sa.i_category_id, wa.i_category_id, ra.i_category_id) AS category_id,
    COALESCE(pa.i_category, sa.i_category, wa.i_category, ra.i_category) AS category,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    (COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0)) AS total_quantity,
    ra.avg_review_sentiment,
    ra.review_count,
    pa.avg_item_price
FROM price_agg pa
LEFT JOIN store_agg sa ON pa.i_category_id = sa.i_category_id
LEFT JOIN web_agg wa ON pa.i_category_id = wa.i_category_id
LEFT JOIN review_agg ra ON pa.i_category_id = ra.i_category_id
ORDER BY total_quantity DESC
LIMIT 10
