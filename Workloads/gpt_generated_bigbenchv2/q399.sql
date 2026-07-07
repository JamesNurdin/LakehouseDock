WITH review_stats AS (
    SELECT
        i.i_category_id,
        i.i_category,
        CAST(i.i_price / 10 AS integer) * 10 AS price_bucket,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        MIN(i.i_price) AS min_price,
        MAX(i.i_price) AS max_price
    FROM items i
    JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category, CAST(i.i_price / 10 AS integer) * 10
)
SELECT
    i_category_id,
    i_category,
    price_bucket,
    review_count,
    avg_sentiment,
    min_price,
    max_price
FROM review_stats
ORDER BY review_count DESC
LIMIT 20
