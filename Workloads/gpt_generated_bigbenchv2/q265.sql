WITH sales_detail AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_customer_id AS customer_id,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        NULL AS store_id,
        ws.ws_customer_id AS customer_id,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        COALESCE(store_id, -1) AS store_id_key,
        store_id,
        i_category_id,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue,
        COUNT(DISTINCT CASE WHEN store_id IS NOT NULL THEN customer_id END) AS distinct_store_customers,
        COUNT(DISTINCT CASE WHEN store_id IS NULL THEN customer_id END) AS distinct_web_customers
    FROM sales_detail
    GROUP BY COALESCE(store_id, -1), store_id, i_category_id, i_category_name
),
store_names AS (
    SELECT s_store_id AS store_id, s_store_name
    FROM stores
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
    COALESCE(sn.s_store_name, 'Web') AS store_name,
    s.store_id_key AS store_id,
    s.i_category_id,
    s.i_category_name,
    s.total_quantity,
    s.total_revenue,
    COALESCE(s.distinct_store_customers, 0) + COALESCE(s.distinct_web_customers, 0) AS total_distinct_customers,
    rev.avg_rating,
    rev.review_count
FROM sales_agg s
LEFT JOIN store_names sn ON s.store_id = sn.store_id
LEFT JOIN reviews_agg rev ON s.i_category_id = rev.i_category_id
ORDER BY store_name, i_category_name
