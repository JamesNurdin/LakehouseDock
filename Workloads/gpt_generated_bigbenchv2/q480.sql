WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_item_id
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        COUNT(pr.pr_review_id) AS review_count,
        SUM(pr.pr_rating) AS sum_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(si.store_quantity) AS total_quantity,
    SUM(si.store_revenue) AS total_revenue,
    COUNT(DISTINCT si.i_item_id) AS distinct_items_sold,
    SUM(COALESCE(ir.review_count, 0)) AS total_review_count,
    CASE
        WHEN SUM(COALESCE(ir.review_count, 0)) = 0 THEN NULL
        ELSE SUM(COALESCE(ir.sum_rating, 0)) / SUM(COALESCE(ir.review_count, 0))
    END AS avg_rating
FROM store_item_sales si
JOIN stores s ON si.ss_store_id = s.s_store_id
LEFT JOIN item_reviews ir ON si.i_item_id = ir.pr_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
