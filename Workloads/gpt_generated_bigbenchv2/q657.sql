WITH sales AS (
    SELECT
        i.i_category_id,
        i.i_category,
        ss.ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        i.i_category_id,
        i.i_category,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        i_category_id,
        i_category,
        SUM(quantity) AS total_quantity,
        SUM(CASE WHEN channel = 'store' THEN quantity ELSE 0 END) AS store_quantity,
        SUM(CASE WHEN channel = 'web' THEN quantity ELSE 0 END) AS web_quantity
    FROM sales
    GROUP BY i_category_id, i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.i_category_id,
    s.i_category,
    s.total_quantity,
    s.store_quantity,
    s.web_quantity,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.i_category_id = r.i_category_id
    AND s.i_category = r.i_category
ORDER BY s.total_quantity DESC
LIMIT 10
