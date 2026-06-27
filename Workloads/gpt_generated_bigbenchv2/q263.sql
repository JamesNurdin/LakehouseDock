WITH unified_sales AS (
    SELECT
        ss.ss_transaction_id AS transaction_id,
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_store_id AS store_id,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_transaction_id AS transaction_id,
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        NULL AS store_id,
        'web' AS channel
    FROM web_sales ws
),

sales_agg AS (
    SELECT
        COALESCE(s.s_store_name, 'Online') AS sales_channel,
        i.i_category_id,
        i.i_category_name,
        SUM(CASE WHEN us.channel = 'store' THEN us.quantity ELSE 0 END) AS store_quantity,
        SUM(CASE WHEN us.channel = 'web' THEN us.quantity ELSE 0 END) AS web_quantity,
        SUM(us.quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT us.customer_id) AS distinct_customers
    FROM unified_sales us
    JOIN items i ON us.item_id = i.i_item_id
    LEFT JOIN stores s ON us.store_id = s.s_store_id
    GROUP BY COALESCE(s.s_store_name, 'Online'), i.i_category_id, i.i_category_name
),

reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    sa.sales_channel,
    sa.i_category_id,
    sa.i_category_name,
    sa.store_quantity,
    sa.web_quantity,
    sa.total_revenue,
    sa.distinct_customers,
    COALESCE(ra.avg_rating, NULL) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count
FROM sales_agg sa
LEFT JOIN reviews_agg ra
    ON sa.i_category_id = ra.i_category_id
ORDER BY sa.i_category_name, sa.sales_channel
