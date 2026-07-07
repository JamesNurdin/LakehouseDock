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
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_quantity * isent.avg_sentiment) FILTER (WHERE isent.avg_sentiment IS NOT NULL)
        / NULLIF(SUM(ss.ss_quantity) FILTER (WHERE isent.avg_sentiment IS NOT NULL), 0) AS avg_review_sentiment
FROM store_sales ss
JOIN items i
    ON ss.ss_item_id = i.i_item_id
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_sentiment isent
    ON i.i_item_id = isent.pr_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
