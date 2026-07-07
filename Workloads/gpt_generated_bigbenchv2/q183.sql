WITH combined_sales AS (
    SELECT
        i.i_category AS i_category,
        i.i_category_id AS i_category_id,
        ss.ss_quantity AS quantity,
        ss.ss_transaction_id AS transaction_id,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        i.i_category AS i_category,
        i.i_category_id AS i_category_id,
        ws.ws_quantity AS quantity,
        ws.ws_transaction_id AS transaction_id,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        i_category,
        i_category_id,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT transaction_id) AS total_transactions,
        SUM(CASE WHEN channel = 'store' THEN quantity ELSE 0 END) AS store_quantity,
        SUM(CASE WHEN channel = 'web' THEN quantity ELSE 0 END) AS web_quantity
    FROM combined_sales
    GROUP BY i_category, i_category_id
),
review_agg AS (
    SELECT
        i.i_category AS i_category,
        i.i_category_id AS i_category_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT
    s.i_category,
    s.i_category_id,
    s.total_quantity,
    s.store_quantity,
    s.web_quantity,
    s.total_transactions,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_category_id = r.i_category_id
ORDER BY s.total_quantity DESC
LIMIT 10
