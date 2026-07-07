WITH item_sentiment AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        COUNT(DISTINCT ss.ss_transaction_id) AS num_transactions,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
),
store_item_sentiment AS (
    SELECT
        ss.ss_store_id,
        AVG(isent.avg_sentiment) AS avg_item_sentiment
    FROM store_sales ss
    JOIN item_sentiment isent ON ss.ss_item_id = isent.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_name,
    sa.num_transactions,
    sa.total_quantity,
    sa.total_revenue,
    sis.avg_item_sentiment
FROM store_sales_agg sa
JOIN stores s ON sa.ss_store_id = s.s_store_id
LEFT JOIN store_item_sentiment sis ON sa.ss_store_id = sis.ss_store_id
ORDER BY sa.total_revenue DESC
LIMIT 10
