WITH item_review_stats AS (
    SELECT
        items.i_item_id,
        items.i_name,
        items.i_category_id,
        items.i_category_name,
        items.i_price,
        items.i_comp_price,
        COUNT(*) AS review_cnt,
        AVG(product_reviews.pr_rating) AS avg_rating
    FROM items
    JOIN product_reviews
        ON product_reviews.pr_item_id = items.i_item_id
    GROUP BY
        items.i_item_id,
        items.i_name,
        items.i_category_id,
        items.i_category_name,
        items.i_price,
        items.i_comp_price
)
SELECT
    i_category_id,
    i_category_name,
    COUNT(*) AS items_with_reviews,
    SUM(review_cnt) AS total_reviews,
    AVG(avg_rating) AS category_avg_rating,
    AVG(i_price) AS avg_item_price,
    AVG(i_price - i_comp_price) AS avg_price_diff
FROM item_review_stats
WHERE review_cnt >= 3
GROUP BY i_category_id, i_category_name
ORDER BY category_avg_rating DESC
