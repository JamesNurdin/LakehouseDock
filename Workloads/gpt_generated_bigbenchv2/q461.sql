WITH review_stats AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
sales_stats AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_transaction_id) AS transaction_count
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(rs.review_count, 0) AS review_count,
    COALESCE(rs.avg_rating, 0) AS avg_rating,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.transaction_count, 0) AS transaction_count,
    CASE
        WHEN COALESCE(ss.total_quantity, 0) = 0 THEN 0
        ELSE COALESCE(rs.avg_rating, 0) * COALESCE(ss.total_quantity, 0)
    END AS rating_quantity_score
FROM items i
LEFT JOIN review_stats rs
    ON rs.pr_item_id = i.i_item_id
LEFT JOIN sales_stats ss
    ON ss.ws_item_id = i.i_item_id
WHERE i.i_price > 10
ORDER BY rating_quantity_score DESC
LIMIT 20
