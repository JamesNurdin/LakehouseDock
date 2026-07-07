WITH sentiment_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
store_sales_by_store_category AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category
)
SELECT
    s.s_store_name,
    ssbsc.i_category,
    ssbsc.total_quantity,
    ssbsc.total_revenue,
    sbc.avg_sentiment
FROM store_sales_by_store_category ssbsc
JOIN stores s
    ON ssbsc.ss_store_id = s.s_store_id
LEFT JOIN sentiment_by_category sbc
    ON ssbsc.i_category_id = sbc.i_category_id
ORDER BY ssbsc.total_revenue DESC
LIMIT 10
