WITH item_sentiment AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    CASE WHEN SUM(ss.ss_quantity) = 0 THEN NULL
         ELSE SUM(ss.ss_quantity * COALESCE(item_sentiment.avg_sentiment, 0)) / SUM(ss.ss_quantity)
    END AS weighted_avg_sentiment
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_sentiment ON i.i_item_id = item_sentiment.pr_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
