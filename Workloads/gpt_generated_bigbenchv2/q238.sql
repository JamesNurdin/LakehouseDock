WITH category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(i.i_price) AS avg_price
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_sentiment AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    cs.i_category_id,
    cs.i_category,
    cs.total_quantity,
    cs.avg_price,
    COALESCE(ct.avg_sentiment, 0) AS avg_sentiment
FROM category_sales cs
LEFT JOIN category_sentiment ct
    ON cs.i_category_id = ct.i_category_id
ORDER BY cs.total_quantity DESC
LIMIT 10
