WITH item_sentiment AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity,
        AVG(i.i_price) AS avg_item_price,
        AVG(item_sent.avg_sentiment) AS avg_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_sentiment item_sent ON i.i_item_id = item_sent.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
)
SELECT
    s.s_store_name,
    sa.i_category,
    sa.total_store_quantity,
    sa.avg_item_price,
    sa.avg_sentiment
FROM store_sales_agg sa
JOIN stores s ON sa.ss_store_id = s.s_store_id
ORDER BY sa.total_store_quantity DESC
LIMIT 100
