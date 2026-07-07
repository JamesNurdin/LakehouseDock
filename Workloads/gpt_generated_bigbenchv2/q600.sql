WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity
    FROM items i
    JOIN store_sales ss ON i.i_item_id = ss.ss_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity
    FROM items i
    JOIN web_sales ws ON i.i_item_id = ws.ws_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    i_cat.i_category_id,
    i_cat.i_category,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(r.avg_sentiment, NULL) AS avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count,
    AVG(i_cat.i_price) AS avg_price
FROM items i_cat
LEFT JOIN store_sales_agg ss
    ON i_cat.i_category_id = ss.i_category_id
    AND i_cat.i_category = ss.i_category
LEFT JOIN web_sales_agg ws
    ON i_cat.i_category_id = ws.i_category_id
    AND i_cat.i_category = ws.i_category
LEFT JOIN reviews_agg r
    ON i_cat.i_category_id = r.i_category_id
    AND i_cat.i_category = r.i_category
GROUP BY
    i_cat.i_category_id,
    i_cat.i_category,
    ss.store_quantity,
    ws.web_quantity,
    r.avg_sentiment,
    r.review_count
ORDER BY total_quantity DESC
LIMIT 10
