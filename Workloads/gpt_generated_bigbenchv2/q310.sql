WITH item_review_stats AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS item_count,
    AVG(i.i_price) AS avg_item_price,
    SUM(ir.review_count) AS total_reviews,
    AVG(ir.avg_rating) AS avg_category_rating,
    SUM(ir.avg_rating * ir.review_count) / NULLIF(SUM(ir.review_count), 0) AS weighted_avg_rating
FROM items i
LEFT JOIN item_review_stats ir
    ON i.i_item_id = ir.pr_item_id
WHERE i.i_price > 0
GROUP BY i.i_category_id, i.i_category_name
ORDER BY avg_category_rating DESC
LIMIT 10
