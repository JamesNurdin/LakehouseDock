WITH store_category_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items_sold
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name
),
category_reviews AS (
    SELECT
        i.i_category_id,
        AVG(pr.pr_rating) AS avg_category_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    scs.i_category_id,
    scs.i_category_name,
    scs.total_quantity,
    scs.total_revenue,
    scs.distinct_items_sold,
    COALESCE(cr.avg_category_rating, 0) AS avg_category_rating,
    COALESCE(cr.review_count, 0) AS review_count
FROM store_category_sales scs
JOIN stores s
    ON scs.ss_store_id = s.s_store_id
LEFT JOIN category_reviews cr
    ON scs.i_category_id = cr.i_category_id
ORDER BY scs.total_revenue DESC
LIMIT 50
