WITH sales_agg AS (
    -- Aggregate physical store sales per store and item category
    SELECT
        ss.ss_store_id AS store_id,
        s.s_store_name AS store_name,
        i.i_category_name AS category_name,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_quantity * i.i_price) AS revenue
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, s.s_store_name, i.i_category_name
    UNION ALL
    -- Aggregate online (web) sales per item category, using a synthetic store id/name
    SELECT
        -1 AS store_id,
        'Online' AS store_name,
        i.i_category_name AS category_name,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_quantity * i.i_price) AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
customer_counts AS (
    -- List each distinct customer who bought items in a given store and category
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_name AS category_name,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        -1 AS store_id,
        i.i_category_name AS category_name,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_rating AS (
    -- Average rating and review count per item category
    SELECT
        i.i_category_name AS category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT
    sa.store_id,
    sa.store_name,
    sa.category_name,
    SUM(sa.quantity) AS total_quantity,
    SUM(sa.revenue) AS total_revenue,
    COUNT(DISTINCT cc.customer_id) AS distinct_customers,
    cr.avg_rating,
    cr.review_count
FROM sales_agg sa
LEFT JOIN customer_counts cc
  ON sa.store_id = cc.store_id
 AND sa.category_name = cc.category_name
LEFT JOIN category_rating cr
  ON sa.category_name = cr.category_name
GROUP BY
    sa.store_id,
    sa.store_name,
    sa.category_name,
    cr.avg_rating,
    cr.review_count
ORDER BY total_revenue DESC
LIMIT 20
