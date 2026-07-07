WITH sales_agg AS (
    SELECT
        ss_item_id AS i_item_id,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS sales_transactions
    FROM store_sales
    GROUP BY ss_item_id
),
reviews_agg AS (
    SELECT
        pr_item_id AS i_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(r.avg_sentiment, 0) AS avg_review_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN sales_agg s ON s.i_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.i_item_id = i.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 100
