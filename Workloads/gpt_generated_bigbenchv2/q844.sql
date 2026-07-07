WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
    COALESCE(ssa.store_quantity, 0) AS store_quantity,
    COALESCE(wsa.web_quantity, 0) AS web_quantity,
    COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
WHERE COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) > 0
ORDER BY total_quantity DESC
LIMIT 10
