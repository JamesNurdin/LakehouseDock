WITH review_stats AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
combined_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        rs.avg_sentiment,
        rs.review_count,
        COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
        COALESCE(ssa.store_customer_count, 0) + COALESCE(wsa.web_customer_count, 0) AS total_customer_count
    FROM items i
    LEFT JOIN review_stats rs ON rs.pr_item_id = i.i_item_id
    LEFT JOIN store_sales_agg ssa ON ssa.ss_item_id = i.i_item_id
    LEFT JOIN web_sales_agg wsa ON wsa.ws_item_id = i.i_item_id
    WHERE rs.avg_sentiment IS NOT NULL
)
SELECT
    i_item_id,
    i_name,
    i_category,
    avg_sentiment,
    review_count,
    total_quantity,
    total_customer_count
FROM combined_sales
ORDER BY avg_sentiment DESC
LIMIT 5
