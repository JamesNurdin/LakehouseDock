WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    sis.store_quantity,
    sis.distinct_customers,
    COALESCE(ir.avg_rating, 0) AS avg_rating,
    COALESCE(ir.review_count, 0) AS review_count
FROM store_item_sales sis
JOIN stores s ON s.s_store_id = sis.ss_store_id
JOIN items i ON i.i_item_id = sis.ss_item_id
LEFT JOIN item_reviews ir ON ir.pr_item_id = i.i_item_id
ORDER BY s.s_store_name, i.i_name
