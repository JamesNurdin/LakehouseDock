WITH all_sales AS (
    -- Combine in‑store and web sales, keeping the channel information
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id   AS store_id,
        ss.ss_item_id    AS item_id,
        ss.ss_quantity   AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        'store'          AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        NULL               AS store_id,
        ws.ws_item_id      AS item_id,
        ws.ws_quantity     AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        'web'              AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    -- Aggregate sales per store (or online) and product category
    SELECT
        COALESCE(s.store_id, -1)               AS store_id,
        i.i_category_id                       AS category_id,
        i.i_category_name                     AS category_name,
        SUM(s.quantity)                       AS total_quantity,
        SUM(s.revenue)                        AS total_revenue,
        COUNT(DISTINCT s.customer_id)         AS distinct_customers
    FROM all_sales s
    JOIN items i ON s.item_id = i.i_item_id
    LEFT JOIN stores st ON s.store_id = st.s_store_id
    GROUP BY
        COALESCE(s.store_id, -1),
        i.i_category_id,
        i.i_category_name
)
SELECT
    CASE WHEN agg.store_id = -1 THEN 'Online' ELSE st.s_store_name END AS store_name,
    agg.category_name,
    agg.total_quantity,
    agg.total_revenue,
    agg.distinct_customers,
    (
        SELECT AVG(pr.pr_rating)
        FROM product_reviews pr
        JOIN items i2 ON pr.pr_item_id = i2.i_item_id
        WHERE i2.i_category_id = agg.category_id
    ) AS avg_rating,
    (
        SELECT COUNT(pr.pr_review_id)
        FROM product_reviews pr
        JOIN items i2 ON pr.pr_item_id = i2.i_item_id
        WHERE i2.i_category_id = agg.category_id
    ) AS review_count
FROM sales_agg agg
LEFT JOIN stores st ON agg.store_id = st.s_store_id
WHERE (
        SELECT AVG(pr.pr_rating)
        FROM product_reviews pr
        JOIN items i2 ON pr.pr_item_id = i2.i_item_id
        WHERE i2.i_category_id = agg.category_id
    ) >= 4
ORDER BY agg.total_revenue DESC
LIMIT 100
