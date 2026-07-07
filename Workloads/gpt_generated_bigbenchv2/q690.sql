WITH combined_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_store_id AS store_id,
        'store' AS sales_channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        NULL AS store_id,
        'web' AS sales_channel
    FROM web_sales
),
sales_by_item AS (
    SELECT
        cs.item_id,
        SUM(cs.quantity) AS total_quantity,
        SUM(cs.quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    JOIN items i
        ON cs.item_id = i.i_item_id
    GROUP BY cs.item_id
),
sentiment_by_item AS (
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
    SUM(sbi.total_quantity) AS category_quantity,
    SUM(sbi.total_revenue) AS category_revenue,
    AVG(senti.avg_sentiment) AS category_avg_sentiment,
    SUM(senti.review_count) AS total_reviews,
    COUNT(DISTINCT sbi.item_id) AS distinct_items
FROM sales_by_item sbi
JOIN items i
    ON sbi.item_id = i.i_item_id
LEFT JOIN sentiment_by_item senti
    ON sbi.item_id = senti.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY category_revenue DESC
LIMIT 10
