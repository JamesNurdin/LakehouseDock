WITH store_category_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(i.i_price) AS avg_item_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
category_sentiment AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    scs.i_category,
    scs.total_quantity,
    scs.avg_item_price,
    cs.avg_sentiment,
    cs.review_count
FROM store_category_sales scs
JOIN stores s ON scs.ss_store_id = s.s_store_id
JOIN category_sentiment cs ON scs.i_category = cs.i_category
ORDER BY scs.total_quantity DESC
LIMIT 100
