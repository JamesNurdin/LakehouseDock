WITH item_sentiment AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        i.i_price,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_item_id,
        i.i_name,
        i.i_category,
        i.i_price
),
ranked_items AS (
    SELECT
        i_item_id,
        i_name,
        i_category,
        i_price,
        review_count,
        avg_sentiment,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY avg_sentiment DESC) AS rn
    FROM item_sentiment
    WHERE review_count >= 10
)
SELECT
    i_item_id,
    i_name,
    i_category,
    i_price,
    review_count,
    avg_sentiment
FROM ranked_items
WHERE rn <= 5
ORDER BY i_category, avg_sentiment DESC
