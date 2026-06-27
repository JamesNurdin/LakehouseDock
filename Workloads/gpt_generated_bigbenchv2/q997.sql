WITH in_store AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_instore_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_instore_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_instore_customers
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
online AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_online_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_online_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    in_store.s_store_name,
    in_store.i_category_name,
    in_store.total_instore_quantity,
    in_store.total_instore_revenue,
    in_store.distinct_instore_customers,
    COALESCE(online.total_online_quantity, 0) AS total_online_quantity,
    COALESCE(online.total_online_revenue, 0) AS total_online_revenue,
    COALESCE(ratings.avg_rating, 0) AS avg_rating,
    COALESCE(ratings.review_count, 0) AS review_count
FROM in_store
LEFT JOIN online
    ON in_store.i_category_id = online.i_category_id
LEFT JOIN ratings
    ON in_store.i_category_id = ratings.i_category_id
ORDER BY in_store.total_instore_revenue DESC
LIMIT 100
