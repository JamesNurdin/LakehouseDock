WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_transaction_id) AS store_transactions,
        COUNT(DISTINCT ss_customer_id) AS store_customers
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws_transaction_id) AS web_transactions,
        COUNT(DISTINCT ws_customer_id) AS web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COALESCE(SUM(sa.store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(wa.web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(sa.store_quantity), 0) + COALESCE(SUM(wa.web_quantity), 0) AS total_quantity,
    COALESCE(SUM(sa.store_quantity) / NULLIF(SUM(sa.store_transactions), 0), 0) AS avg_store_quantity_per_transaction,
    COALESCE(SUM(wa.web_quantity) / NULLIF(SUM(wa.web_transactions), 0), 0) AS avg_web_quantity_per_transaction,
    COALESCE(AVG(r.avg_sentiment), NULL) AS avg_sentiment,
    COALESCE(SUM(r.review_count), 0) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity DESC
LIMIT 20
