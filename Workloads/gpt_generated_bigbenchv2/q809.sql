WITH item_sentiment AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_item_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(i.i_price) AS avg_price,
        AVG(COALESCE(isent.avg_sentiment, 0)) AS avg_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_sentiment isent ON i.i_item_id = isent.item_id
    GROUP BY ss.ss_store_id, i.i_category
)
SELECT
    s.s_store_name,
    sis.category,
    sis.total_quantity,
    sis.avg_price,
    sis.avg_sentiment
FROM store_item_sales sis
JOIN stores s ON sis.store_id = s.s_store_id
ORDER BY sis.total_quantity DESC
LIMIT 100
