WITH category_stats AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        AVG(i.i_price) AS avg_price,
        AVG(i.i_comp_price) AS avg_comp_price,
        AVG(i.i_price - i.i_comp_price) AS avg_price_diff,
        SUM(CASE WHEN pr.pr_sentiment > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(pr.pr_review_id) AS pct_positive_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    category_id,
    category_name,
    review_count,
    avg_sentiment,
    avg_price,
    avg_comp_price,
    avg_price_diff,
    pct_positive_sentiment
FROM category_stats
ORDER BY review_count DESC
LIMIT 10
