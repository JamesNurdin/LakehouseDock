WITH item_review_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category
),
store_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    ira.i_category_id,
    ira.i_category,
    COUNT(DISTINCT ira.i_item_id) AS num_items,
    ROUND(AVG(ira.avg_sentiment), 2) AS avg_sentiment_per_category,
    SUM(COALESCE(ssa.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wsa.web_quantity, 0)) AS total_web_quantity,
    SUM(COALESCE(ssa.store_customer_count, 0) + COALESCE(wsa.web_customer_count, 0)) AS total_distinct_customers_across_channels
FROM item_review_agg ira
LEFT JOIN store_sales_agg ssa ON ssa.i_item_id = ira.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.i_item_id = ira.i_item_id
GROUP BY ira.i_category_id, ira.i_category
ORDER BY total_store_quantity DESC
LIMIT 10
