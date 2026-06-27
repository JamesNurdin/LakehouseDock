WITH item_review_stats AS (
    SELECT 
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY 
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price
)
SELECT 
    irs.i_category_name,
    irs.i_item_id,
    irs.i_name,
    irs.i_price - irs.i_comp_price AS price_diff,
    irs.review_count,
    irs.avg_rating,
    ROW_NUMBER() OVER (PARTITION BY irs.i_category_name ORDER BY irs.avg_rating DESC NULLS LAST) AS rank_in_category
FROM item_review_stats irs
WHERE irs.review_count > 0
ORDER BY irs.i_category_name, rank_in_category
LIMIT 50
