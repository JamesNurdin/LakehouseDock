WITH item_reviews AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    AVG(COALESCE(ir.avg_sentiment, 0)) AS avg_item_sentiment
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_reviews ir ON ir.pr_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_id, s.s_store_name, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
