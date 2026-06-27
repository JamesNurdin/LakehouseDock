WITH review_stats AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating,
        MIN(pr_rating) AS min_rating,
        MAX(pr_rating) AS max_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    rs.review_count,
    rs.avg_rating,
    rs.min_rating,
    rs.max_rating,
    ROW_NUMBER() OVER (PARTITION BY i.i_category_name ORDER BY rs.avg_rating DESC) AS category_rank
FROM items i
JOIN review_stats rs
    ON rs.pr_item_id = i.i_item_id
WHERE rs.review_count >= 5
ORDER BY i.i_category_name, rs.avg_rating DESC
LIMIT 20
