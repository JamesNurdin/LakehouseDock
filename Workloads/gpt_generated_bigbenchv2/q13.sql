WITH avg_sentiment_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),

sales_by_store_category AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category
)

SELECT
    s.s_store_name,
    sbc.i_category,
    sbc.total_quantity,
    asc.avg_sentiment
FROM sales_by_store_category sbc
JOIN stores s
    ON sbc.ss_store_id = s.s_store_id
LEFT JOIN avg_sentiment_by_category asc
    ON sbc.i_category_id = asc.i_category_id
ORDER BY sbc.total_quantity DESC
LIMIT 100
