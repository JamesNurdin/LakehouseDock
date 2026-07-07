WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items_sold
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
),
store_review_agg AS (
    SELECT
        ss_store_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM (
        SELECT DISTINCT ss.ss_store_id AS ss_store_id, pr.pr_review_id, pr.pr_sentiment
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    ) distinct_reviews
    GROUP BY ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ss_agg.total_quantity,
    ss_agg.total_revenue,
    ss_agg.distinct_items_sold,
    sr_agg.avg_sentiment,
    sr_agg.review_count
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN store_review_agg sr_agg ON ss_agg.ss_store_id = sr_agg.ss_store_id
ORDER BY ss_agg.total_revenue DESC
LIMIT 10
