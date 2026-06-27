WITH item_stats AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_cnt,
        AVG(pr_rating) AS avg_rating,
        MIN(pr_rating) AS min_rating,
        MAX(pr_rating) AS max_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
item_with_category AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        i.i_class_id,
        s.review_cnt,
        s.avg_rating,
        s.min_rating,
        s.max_rating
    FROM items i
    JOIN item_stats s ON s.pr_item_id = i.i_item_id
),
ranked_items AS (
    SELECT
        iwc.*, 
        ROW_NUMBER() OVER (
            PARTITION BY iwc.i_category_id 
            ORDER BY iwc.avg_rating DESC, iwc.review_cnt DESC
        ) AS rank_in_category
    FROM item_with_category iwc
)
SELECT
    ri.i_category_id,
    ri.i_category_name,
    ri.i_item_id,
    ri.i_name,
    ri.i_price,
    ri.i_comp_price,
    ri.review_cnt,
    ri.avg_rating,
    ri.min_rating,
    ri.max_rating,
    (ri.i_price - ri.i_comp_price) AS price_diff
FROM ranked_items ri
WHERE ri.rank_in_category <= 3
ORDER BY ri.i_category_id, ri.rank_in_category
