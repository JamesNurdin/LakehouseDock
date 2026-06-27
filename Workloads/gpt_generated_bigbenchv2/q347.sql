WITH item_ratings AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_rating) AS avg_rating,
        (i.i_price - i.i_comp_price) AS price_diff
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
),
ranked_items AS (
    SELECT
        ir.i_category_name,
        ir.i_item_id,
        ir.i_name,
        ir.i_price,
        ir.i_comp_price,
        ir.price_diff,
        ir.review_count,
        ir.avg_rating,
        ROW_NUMBER() OVER (
            PARTITION BY ir.i_category_name
            ORDER BY ir.avg_rating DESC NULLS LAST, ir.review_count DESC
        ) AS rating_rank
    FROM item_ratings ir
    WHERE ir.review_count > 0
)
SELECT
    ri.i_category_name,
    ri.i_item_id,
    ri.i_name,
    ri.i_price,
    ri.i_comp_price,
    ri.price_diff,
    ri.review_count,
    ri.avg_rating,
    ri.rating_rank
FROM ranked_items ri
WHERE ri.rating_rank <= 3
ORDER BY ri.i_category_name, ri.rating_rank
