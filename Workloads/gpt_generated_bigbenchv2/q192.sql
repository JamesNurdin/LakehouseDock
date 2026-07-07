WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(*) AS store_transactions
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(*) AS web_transactions
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category,
    i.i_price,
    COALESCE(ssa.store_quantity, 0) AS total_store_quantity,
    COALESCE(wsa.web_quantity, 0) AS total_web_quantity,
    COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
    COALESCE(ssa.store_transactions, 0) AS store_transactions,
    COALESCE(wsa.web_transactions, 0) AS web_transactions,
    r.avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 20
