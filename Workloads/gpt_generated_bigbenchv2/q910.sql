WITH sales_by_store_category AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        i.i_category_id AS category_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items_sold
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category
),
sentiment_by_category AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    sbc.store_id,
    sbc.store_name,
    sbc.category_id,
    sbc.category,
    sbc.total_quantity,
    sbc.distinct_items_sold,
    COALESCE(sc.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(sc.review_count, 0) AS review_count
FROM sales_by_store_category sbc
LEFT JOIN sentiment_by_category sc
    ON sbc.category_id = sc.category_id AND sbc.category = sc.category
ORDER BY sbc.total_quantity DESC
LIMIT 100
