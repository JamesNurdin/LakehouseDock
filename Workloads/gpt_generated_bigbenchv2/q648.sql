WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_quantity * i.i_price) AS total_sales_revenue,
        AVG(i.i_price) AS avg_item_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
),
store_review_agg AS (
    SELECT
        ss.ss_store_id,
        AVG(pr.pr_sentiment) AS avg_review_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_name,
    sa.total_quantity_sold,
    sa.total_sales_revenue,
    sa.avg_item_price,
    ra.avg_review_sentiment
FROM store_sales_agg sa
JOIN store_review_agg ra ON sa.ss_store_id = ra.ss_store_id
JOIN stores s ON sa.ss_store_id = s.s_store_id
ORDER BY sa.total_sales_revenue DESC
LIMIT 5
