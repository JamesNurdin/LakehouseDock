WITH store_sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_sales_amount
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_name, i.i_category
),
review_sentiment_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    ss.s_store_name,
    ss.i_category,
    ss.total_quantity,
    ss.total_sales_amount,
    rs.avg_sentiment,
    rs.review_count
FROM store_sales_agg ss
LEFT JOIN review_sentiment_agg rs ON ss.i_category = rs.i_category
ORDER BY ss.s_store_name, ss.i_category
