WITH review_data AS (
    SELECT
        i.i_category,
        i.i_price,
        floor(i.i_price / 10) * 10 AS price_bucket,
        pr.pr_sentiment,
        pr.pr_store
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
)
SELECT
    i_category,
    price_bucket,
    COUNT(*) AS review_count,
    AVG(pr_sentiment) AS avg_sentiment
FROM review_data
WHERE pr_store = 'Online'
GROUP BY i_category, price_bucket
ORDER BY avg_sentiment DESC
LIMIT 10
