WITH item_sentiment AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category_id,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    COALESCE(AVG(item_sentiment.avg_sentiment), 0) AS avg_item_sentiment,
    SUM(COALESCE(item_sentiment.review_count, 0)) AS total_review_count
FROM store_sales ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_sentiment
    ON i.i_item_id = item_sentiment.pr_item_id
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_category_id,
    i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 20
