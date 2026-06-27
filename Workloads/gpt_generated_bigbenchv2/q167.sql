WITH
    -- Basic item information
    item_info AS (
        SELECT
            i_item_id,
            i_category_id,
            i_category_name,
            i_price
        FROM items
    ),
    -- Review aggregates per item (sum of ratings and count of reviews)
    review_stats AS (
        SELECT
            pr_item_id,
            SUM(pr_rating) AS rating_sum,
            COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    -- Store‑sales aggregates per item
    store_sales_stats AS (
        SELECT
            ss_item_id,
            SUM(ss_quantity) AS store_qty
        FROM store_sales
        GROUP BY ss_item_id
    ),
    -- Web‑sales aggregates per item
    web_sales_stats AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS web_qty
        FROM web_sales
        GROUP BY ws_item_id
    ),
    -- Distinct stores that sold items in each category
    store_sales_by_category AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            COUNT(DISTINCT ss.ss_store_id) AS distinct_store_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT
    ii.i_category_id,
    ii.i_category_name,
    COUNT(DISTINCT ii.i_item_id) AS distinct_item_count,
    SUM(COALESCE(rs.review_count, 0)) AS total_reviews,
    CASE
        WHEN SUM(COALESCE(rs.review_count, 0)) = 0 THEN NULL
        ELSE SUM(COALESCE(rs.rating_sum, 0)) / SUM(COALESCE(rs.review_count, 0))
    END AS avg_rating,
    SUM(COALESCE(ss.store_qty, 0)) AS total_store_quantity,
    SUM(COALESCE(ws.web_qty, 0)) AS total_web_quantity,
    SUM((COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) * ii.i_price) AS total_revenue,
    COALESCE(ssc.distinct_store_count, 0) AS distinct_store_count
FROM item_info ii
LEFT JOIN review_stats rs ON rs.pr_item_id = ii.i_item_id
LEFT JOIN store_sales_stats ss ON ss.ss_item_id = ii.i_item_id
LEFT JOIN web_sales_stats ws ON ws.ws_item_id = ii.i_item_id
LEFT JOIN store_sales_by_category ssc
    ON ssc.i_category_id = ii.i_category_id
    AND ssc.i_category_name = ii.i_category_name
GROUP BY
    ii.i_category_id,
    ii.i_category_name,
    ssc.distinct_store_count
ORDER BY total_revenue DESC
LIMIT 10
