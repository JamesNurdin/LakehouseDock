WITH sales_by_store_item AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS item_quantity,
        SUM(ss.ss_quantity * i.i_price) AS item_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
item_sentiment AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    SUM(sbi.item_quantity) AS total_quantity,
    SUM(sbi.item_revenue) AS total_revenue,
    SUM(sbi.item_quantity * COALESCE(isent.avg_sentiment, 0)) / NULLIF(SUM(sbi.item_quantity), 0) AS weighted_avg_sentiment
FROM sales_by_store_item sbi
LEFT JOIN item_sentiment isent
    ON sbi.ss_item_id = isent.pr_item_id
JOIN stores s
    ON sbi.ss_store_id = s.s_store_id
GROUP BY s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
