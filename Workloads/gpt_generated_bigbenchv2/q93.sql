WITH
store_agg AS (
    SELECT
        ss_item_id AS i_item_id,
        SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id AS i_item_id,
        SUM(ws_quantity) AS total_web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id AS i_item_id,
        COUNT(*) AS review_count,
        AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(sa.total_store_qty, 0) AS total_store_qty,
    COALESCE(wa.total_web_qty, 0) AS total_web_qty,
    (COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0)) AS total_quantity,
    (i.i_price * (COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0))) AS total_revenue,
    COALESCE(ra.review_count, 0) AS review_count,
    ra.avg_sentiment
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
WHERE (COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0)) > 0
ORDER BY total_revenue DESC
LIMIT 20
