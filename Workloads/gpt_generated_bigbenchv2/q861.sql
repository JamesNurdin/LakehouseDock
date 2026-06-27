WITH item_review_stats AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
item_with_stats AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        i.i_price - i.i_comp_price AS price_diff,
        COALESCE(irs.review_count, 0) AS review_count,
        COALESCE(irs.avg_rating, 0) AS avg_rating
    FROM items i
    LEFT JOIN item_review_stats irs
        ON irs.pr_item_id = i.i_item_id
),
ranked_items AS (
    SELECT
        iws.*,
        ROW_NUMBER() OVER (
            PARTITION BY iws.i_category_id
            ORDER BY iws.avg_rating DESC, iws.review_count DESC
        ) AS rank_in_category
    FROM item_with_stats iws
)
SELECT
    iws.i_category_id,
    iws.i_category_name,
    iws.i_item_id,
    iws.i_name,
    iws.i_price,
    iws.i_comp_price,
    iws.price_diff,
    iws.avg_rating,
    iws.review_count
FROM ranked_items iws
WHERE iws.rank_in_category <= 5
ORDER BY iws.i_category_id, iws.rank_in_category
