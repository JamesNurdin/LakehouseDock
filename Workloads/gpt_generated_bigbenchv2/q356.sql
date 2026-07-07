WITH
store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_qty
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_qty
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_base AS (
    SELECT DISTINCT
        i_category_id,
        i_category
    FROM items
)
SELECT
    cb.i_category_id,
    cb.i_category,
    COALESCE(sa.total_store_qty, 0) AS total_store_quantity,
    COALESCE(wa.total_web_qty, 0) AS total_web_quantity,
    COALESCE(ra.review_count, 0) AS review_count,
    ra.avg_sentiment
FROM category_base cb
LEFT JOIN store_agg sa
    ON cb.i_category_id = sa.i_category_id
    AND cb.i_category = sa.i_category
LEFT JOIN web_agg wa
    ON cb.i_category_id = wa.i_category_id
    AND cb.i_category = wa.i_category
LEFT JOIN review_agg ra
    ON cb.i_category_id = ra.i_category_id
    AND cb.i_category = ra.i_category
ORDER BY (COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0)) DESC
LIMIT 10
