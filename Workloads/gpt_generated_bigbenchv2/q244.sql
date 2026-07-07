WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
product_sentiment_agg AS (
    SELECT
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    agg.category,
    agg.total_quantity,
    agg.total_revenue,
    sent.avg_sentiment
FROM store_sales_agg agg
JOIN stores s
    ON agg.store_id = s.s_store_id
LEFT JOIN product_sentiment_agg sent
    ON agg.category = sent.category
ORDER BY s.s_store_name, agg.category
