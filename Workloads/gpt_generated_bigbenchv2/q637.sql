WITH sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_transaction_id) AS transaction_count
    FROM store_sales
    GROUP BY ss_item_id
),
reviews_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    i.i_comp_price,
    i.i_price - i.i_comp_price AS price_diff,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(s.transaction_count, 0) AS total_transactions,
    COALESCE(s.total_quantity, 0) * i.i_price AS total_revenue,
    COALESCE(r.avg_rating, 0) AS average_rating,
    COALESCE(r.review_count, 0) AS total_reviews
FROM items i
LEFT JOIN sales_agg s ON s.ss_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
WHERE i.i_price > 20.00
ORDER BY total_quantity_sold DESC
LIMIT 20
