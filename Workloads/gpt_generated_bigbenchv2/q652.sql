WITH sales_agg AS (
    SELECT 
        ss_item_id,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM store_sales
    GROUP BY ss_item_id
),
review_agg AS (
    SELECT 
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT 
    i.i_category,
    i.i_category_id,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(s.total_quantity * i.i_price), 0) AS total_sales_amount,
    COALESCE(AVG(r.avg_sentiment), 0) AS avg_item_sentiment,
    COALESCE(SUM(r.review_count), 0) AS total_reviews
FROM items i
LEFT JOIN sales_agg s ON s.ss_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
