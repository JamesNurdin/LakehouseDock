WITH category_review_stats AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(i.i_price) AS avg_price,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    i_category_id,
    i_category,
    avg_price,
    avg_sentiment,
    review_count
FROM category_review_stats
WHERE review_count >= 10
ORDER BY avg_price DESC
