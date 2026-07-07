WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category,
    i.i_name,
    i.i_price,
    COALESCE(sa.total_store_quantity, 0) AS store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS web_quantity,
    COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
ORDER BY i.i_category, i.i_name
