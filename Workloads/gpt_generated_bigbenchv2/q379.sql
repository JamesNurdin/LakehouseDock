WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss_store_id) AS distinct_store_count
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0) AS total_quantity,
    (COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0)) * i.i_price AS total_revenue,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(ss.distinct_store_count, 0) AS distinct_store_count
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.pr_item_id
ORDER BY total_revenue DESC
LIMIT 20
