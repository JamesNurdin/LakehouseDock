WITH item_sentiment AS (
    SELECT
        i.i_item_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
store_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
)
SELECT
    i_sent.i_category,
    COALESCE(sa.store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.web_quantity, 0) AS total_web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    i_sent.avg_sentiment,
    i_sent.review_count
FROM item_sentiment i_sent
LEFT JOIN store_agg sa ON sa.item_id = i_sent.i_item_id
LEFT JOIN web_agg wa ON wa.item_id = i_sent.i_item_id
WHERE i_sent.avg_sentiment > 3
ORDER BY total_quantity DESC
LIMIT 10
