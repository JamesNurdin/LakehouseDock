WITH item_review_stats AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_cnt
    FROM items i
    JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        i.i_price,
        i.i_comp_price
)
SELECT
    i_category_name,
    AVG(i_price) AS avg_price,
    AVG(i_comp_price) AS avg_comp_price,
    AVG(i_price - i_comp_price) AS avg_discount,
    AVG(avg_rating) AS avg_item_rating,
    SUM(review_cnt) AS total_reviews
FROM item_review_stats
GROUP BY i_category_name
ORDER BY avg_item_rating DESC
