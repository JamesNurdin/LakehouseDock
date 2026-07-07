SELECT
    items.i_category,
    floor(items.i_price / 10) * 10 AS price_bucket,
    COUNT(product_reviews.pr_review_id) AS review_count,
    AVG(product_reviews.pr_sentiment) AS avg_sentiment
FROM items
JOIN product_reviews
    ON product_reviews.pr_item_id = items.i_item_id
WHERE product_reviews.pr_sentiment > 0
GROUP BY items.i_category, floor(items.i_price / 10) * 10
ORDER BY avg_sentiment DESC, review_count DESC
