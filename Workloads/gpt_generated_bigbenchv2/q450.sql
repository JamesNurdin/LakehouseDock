WITH item_review_stats AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating,
        MIN(pr.pr_rating) AS min_rating,
        MAX(pr.pr_rating) AS max_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    i.i_comp_price,
    (i.i_price - i.i_comp_price) AS price_difference,
    irs.review_count,
    irs.avg_rating,
    irs.min_rating,
    irs.max_rating,
    RANK() OVER (PARTITION BY i.i_category_name ORDER BY irs.avg_rating DESC) AS category_rating_rank
FROM items i
JOIN item_review_stats irs
    ON i.i_item_id = irs.pr_item_id
WHERE i.i_price > 0
ORDER BY i.i_category_name, category_rating_rank
LIMIT 20
