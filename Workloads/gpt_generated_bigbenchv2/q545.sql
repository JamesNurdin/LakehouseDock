WITH item_ratings AS (
    SELECT
        i.i_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
    CASE
        WHEN SUM(ss.ss_quantity) > 0
        THEN SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) / SUM(ss.ss_quantity)
        ELSE NULL
    END AS weighted_average_item_rating,
    SUM(COALESCE(ir.review_count, 0)) AS total_reviews_of_items_sold
FROM store_sales ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_ratings ir
    ON i.i_item_id = ir.item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
