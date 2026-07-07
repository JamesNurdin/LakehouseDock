WITH price_stats AS (
    SELECT
        i_category,
        i_category_id,
        AVG(i_price) AS avg_price,
        AVG(i_comp_price) AS avg_comp_price
    FROM items
    GROUP BY i_category, i_category_id
),
sentiment_stats AS (
    SELECT
        i.i_category,
        i.i_category_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT
    ps.i_category,
    ps.i_category_id,
    ps.avg_price,
    ps.avg_comp_price,
    ss.avg_sentiment,
    ss.review_count,
    (ps.avg_price - ps.avg_comp_price) AS avg_price_diff
FROM price_stats ps
JOIN sentiment_stats ss
    ON ss.i_category = ps.i_category
    AND ss.i_category_id = ps.i_category_id
ORDER BY ss.avg_sentiment DESC
LIMIT 10
