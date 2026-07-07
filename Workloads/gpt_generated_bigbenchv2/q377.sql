WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    si.ss_store_id,
    SUM(si.total_quantity) AS store_total_quantity,
    SUM(si.total_revenue) AS store_total_revenue,
    AVG(ir.avg_sentiment) AS store_avg_sentiment,
    COUNT(DISTINCT si.ss_item_id) AS distinct_items_sold
FROM store_item_sales si
JOIN stores s ON si.ss_store_id = s.s_store_id
LEFT JOIN item_reviews ir ON si.ss_item_id = ir.pr_item_id
GROUP BY s.s_store_name, si.ss_store_id
ORDER BY store_total_revenue DESC
LIMIT 10
