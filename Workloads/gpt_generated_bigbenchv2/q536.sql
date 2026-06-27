WITH item_review_stats AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count,
        (i.i_price - i.i_comp_price) AS price_diff
    FROM items i
    JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price, i.i_comp_price
)
SELECT
    irs.i_item_id,
    irs.i_name,
    irs.i_category_name,
    irs.avg_rating,
    irs.review_count,
    irs.price_diff,
    DENSE_RANK() OVER (PARTITION BY irs.i_category_id ORDER BY irs.avg_rating DESC) AS rating_rank
FROM item_review_stats irs
WHERE irs.review_count >= 5
ORDER BY irs.i_category_name, rating_rank
