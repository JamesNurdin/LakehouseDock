WITH item_reviews AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_cnt,
        AVG(pr_rating) AS avg_rating,
        SUM(pr_rating) AS total_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
item_details AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        i.i_class_id,
        COALESCE(ir.review_cnt, 0) AS review_cnt,
        COALESCE(ir.avg_rating, 0) AS avg_rating,
        i.i_price - i.i_comp_price AS price_diff
    FROM items i
    LEFT JOIN item_reviews ir
        ON ir.pr_item_id = i.i_item_id
)
SELECT
    id.i_category_name,
    COUNT(DISTINCT id.i_item_id) AS num_items,
    SUM(id.review_cnt) AS total_reviews,
    AVG(id.avg_rating) FILTER (WHERE id.review_cnt > 0) AS avg_rating_per_item,
    AVG(id.i_price) AS avg_price,
    AVG(id.price_diff) AS avg_price_diff,
    MAX(id.avg_rating) AS max_item_rating,
    MIN(id.avg_rating) AS min_item_rating
FROM item_details id
GROUP BY id.i_category_name
ORDER BY avg_rating_per_item DESC
LIMIT 10
