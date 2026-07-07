WITH store_agg AS (
    SELECT
        ss_item_id AS i_item_id,
        SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id AS i_item_id,
        SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id AS i_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(s.store_qty, 0) AS store_qty,
    COALESCE(w.web_qty, 0) AS web_qty,
    COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty,
    r.avg_sentiment,
    r.review_cnt
FROM items i
LEFT JOIN store_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN web_agg w ON i.i_item_id = w.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.i_item_id
WHERE COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) > 0
ORDER BY total_qty DESC
LIMIT 10
