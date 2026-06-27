WITH sales_agg AS (
    -- Aggregate store and web sales per store (or online) and item category
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS customer_count
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name

    UNION ALL

    SELECT
        NULL AS store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS customer_count
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    -- Average rating and review count per item category
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
stores_info AS (
    SELECT
        s.s_store_id,
        s.s_store_name
    FROM stores s
)
SELECT
    COALESCE(sa.store_id, -1) AS store_id,
    CASE WHEN sa.store_id IS NULL THEN 'Online' ELSE si.s_store_name END AS store_name,
    sa.i_category_id,
    sa.i_category_name,
    sa.total_quantity,
    sa.total_revenue,
    sa.customer_count,
    r.avg_rating,
    r.review_count
FROM sales_agg sa
LEFT JOIN stores_info si
    ON sa.store_id = si.s_store_id
LEFT JOIN reviews_agg r
    ON sa.i_category_id = r.i_category_id
ORDER BY sa.total_revenue DESC NULLS LAST
LIMIT 100
