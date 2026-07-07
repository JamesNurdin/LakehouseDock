WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    COUNT(DISTINCT i.i_item_id) AS item_count,
    SUM(COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(ssa.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wsa.web_quantity, 0)) AS total_web_quantity,
    AVG(r.avg_sentiment) AS avg_category_sentiment,
    SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.item_id = i.i_item_id
LEFT JOIN review_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 20
