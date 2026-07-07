WITH item_reviews_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    i.i_name,
    i.i_price,
    r.avg_sentiment,
    r.review_count,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
FROM items i
LEFT JOIN item_reviews_agg r ON i.i_item_id = r.i_item_id
LEFT JOIN store_sales_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN web_sales_agg w ON i.i_item_id = w.i_item_id
WHERE i.i_category IS NOT NULL
ORDER BY r.avg_sentiment DESC NULLS LAST
LIMIT 100
