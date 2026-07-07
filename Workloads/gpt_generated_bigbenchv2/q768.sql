WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss_transaction_id) AS store_transactions,
        COUNT(DISTINCT ss_customer_id) AS store_customers
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws_transaction_id) AS web_transactions,
        COUNT(DISTINCT ws_customer_id) AS web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_category_id,
    COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_transactions, 0) AS store_transactions,
    COALESCE(ws.web_transactions, 0) AS web_transactions,
    COALESCE(ss.store_customers, 0) + COALESCE(ws.web_customers, 0) AS distinct_customers,
    r.avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
