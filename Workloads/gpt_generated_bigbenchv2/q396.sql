WITH sales_union AS (
    -- Combine in‑store and online sales into one stream
    SELECT
        ss.ss_transaction_id      AS transaction_id,
        ss.ss_customer_id         AS customer_id,
        ss.ss_store_id            AS store_id,
        ss.ss_item_id             AS item_id,
        ss.ss_quantity            AS quantity,
        'store'                   AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_transaction_id      AS transaction_id,
        ws.ws_customer_id         AS customer_id,
        NULL                      AS store_id,
        ws.ws_item_id             AS item_id,
        ws.ws_quantity            AS quantity,
        'web'                     AS channel
    FROM web_sales ws
),
sales_agg AS (
    -- Aggregate revenue and customer counts per store (or online) and product category
    SELECT
        COALESCE(su.store_id, -1)                     AS store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(su.quantity * i.i_price)                 AS total_revenue,
        COUNT(DISTINCT su.customer_id)               AS unique_customers,
        SUM(CASE WHEN su.channel = 'store' THEN su.quantity ELSE 0 END) AS store_quantity,
        SUM(CASE WHEN su.channel = 'web'   THEN su.quantity ELSE 0 END) AS web_quantity
    FROM sales_union su
    JOIN items i ON su.item_id = i.i_item_id
    GROUP BY COALESCE(su.store_id, -1), i.i_category_id, i.i_category_name
)
SELECT
    CASE WHEN sa.store_id = -1 THEN 'Online' ELSE s.s_store_name END AS store_name,
    sa.i_category_name                                 AS category,
    sa.total_revenue,
    sa.unique_customers,
    sa.store_quantity,
    sa.web_quantity,
    (
        SELECT AVG(pr.pr_rating)
        FROM product_reviews pr
        JOIN items i2 ON pr.pr_item_id = i2.i_item_id
        WHERE i2.i_category_id = sa.i_category_id
    )                                                  AS avg_rating,
    (
        SELECT COUNT(pr.pr_review_id)
        FROM product_reviews pr
        JOIN items i2 ON pr.pr_item_id = i2.i_item_id
        WHERE i2.i_category_id = sa.i_category_id
    )                                                  AS review_count
FROM sales_agg sa
LEFT JOIN stores s ON sa.store_id = s.s_store_id
ORDER BY sa.total_revenue DESC
LIMIT 20
