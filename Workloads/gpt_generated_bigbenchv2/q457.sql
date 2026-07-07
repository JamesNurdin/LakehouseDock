WITH combined_sales AS (
    SELECT
        ss.ss_transaction_id AS transaction_id,
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_ts AS ts,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_transaction_id AS transaction_id,
        ws.ws_customer_id AS customer_id,
        NULL AS store_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_ts AS ts,
        'web' AS channel
    FROM web_sales ws
),
sales_with_details AS (
    SELECT
        cs.transaction_id,
        cs.customer_id,
        cs.store_id,
        cs.item_id,
        cs.quantity,
        cs.ts,
        cs.channel,
        i.i_name,
        i.i_category,
        i.i_category_id,
        i.i_price,
        c.c_name,
        s.s_store_name
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    JOIN customers c ON cs.customer_id = c.c_customer_id
    LEFT JOIN stores s ON cs.store_id = s.s_store_id
)
SELECT
    swd.i_category,
    swd.i_category_id,
    COUNT(DISTINCT swd.customer_id) AS distinct_customers,
    SUM(swd.quantity) AS total_quantity_sold,
    SUM(swd.quantity * swd.i_price) AS total_revenue,
    AVG(pr.pr_sentiment) AS avg_review_sentiment,
    COUNT(pr.pr_review_id) AS review_count
FROM sales_with_details swd
LEFT JOIN product_reviews pr ON pr.pr_item_id = swd.item_id
GROUP BY swd.i_category, swd.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
