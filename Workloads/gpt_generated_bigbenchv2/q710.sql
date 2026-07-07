WITH review_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category
),
sales AS (
    SELECT
        ss.ss_transaction_id AS transaction_id,
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_ts AS ts,
        'store' AS channel,
        ss.ss_store_id AS store_id
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_transaction_id AS transaction_id,
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_ts AS ts,
        'web' AS channel,
        NULL AS store_id
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        s.item_id,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY s.item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(sa.total_quantity) AS category_total_quantity,
    SUM(sa.total_revenue) AS category_total_revenue,
    AVG(ra.avg_sentiment) AS category_avg_sentiment,
    SUM(ra.review_count) AS category_review_count,
    COUNT(DISTINCT sa.item_id) AS distinct_items_sold
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY category_total_revenue DESC
