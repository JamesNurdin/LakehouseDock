WITH combined_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_store_id AS store_id,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        NULL AS store_id,
        'web' AS channel
    FROM web_sales
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.quantity * i.i_price) AS total_revenue,
    COALESCE(pr.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(pr.review_count, 0) AS review_count
FROM combined_sales cs
JOIN items i
    ON cs.item_id = i.i_item_id
JOIN customers c
    ON cs.customer_id = c.c_customer_id
LEFT JOIN stores s
    ON cs.store_id = s.s_store_id
LEFT JOIN (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
) pr
    ON i.i_item_id = pr.pr_item_id
GROUP BY
    i.i_item_id,
    i.i_name,
    i.i_category,
    pr.avg_sentiment,
    pr.review_count
ORDER BY total_revenue DESC
LIMIT 10
