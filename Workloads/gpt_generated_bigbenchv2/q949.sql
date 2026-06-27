WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_category_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    ss.ss_store_id,
    ss.s_store_name,
    ss.i_category_id,
    ss.i_category_name,
    ss.total_store_quantity,
    ss.total_store_revenue,
    ss.store_customer_count,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(r.avg_category_rating, 0) AS avg_category_rating,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ws.i_category_id = ss.i_category_id
    AND ws.i_category_name = ss.i_category_name
LEFT JOIN reviews_agg r
    ON r.i_category_id = ss.i_category_id
    AND r.i_category_name = ss.i_category_name
ORDER BY ss.total_store_quantity DESC
LIMIT 100
