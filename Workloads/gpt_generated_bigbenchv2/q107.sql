WITH high_price_items AS (
    SELECT i_item_id, i_category, i_price
    FROM items
    WHERE i_price > 100.00
)
SELECT
    hp.i_category,
    COUNT(pr.pr_review_id) AS review_count,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    AVG(hp.i_price) AS avg_price
FROM product_reviews pr
JOIN high_price_items hp
    ON pr.pr_item_id = hp.i_item_id
GROUP BY hp.i_category
ORDER BY review_count DESC
LIMIT 10
