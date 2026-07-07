WITH review_stats AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
sales_stats AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_quantity_sold,
        COUNT(*) AS sales_transaction_count
    FROM store_sales
    GROUP BY ss_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(rs.review_count, 0) AS review_count,
    rs.avg_sentiment,
    COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
    ss.sales_transaction_count
FROM items i
LEFT JOIN review_stats rs ON rs.pr_item_id = i.i_item_id
LEFT JOIN sales_stats ss ON ss.ss_item_id = i.i_item_id
ORDER BY i.i_category, i.i_price DESC
